module.exports = function(context) {

    var path              = crequire('path'),
        fs                = require('fs'),
        crypto            = require('crypto'),
        Q                 = require('q'),
        cordova_util      = context.requireCordovaModule('cordova-lib/src/cordova/util'),
        platforms         = context.requireCordovaModule('cordova-lib/src/platforms/platforms'),
        Parser            = context.requireCordovaModule('cordova-lib/src/cordova/metadata/parser'),
        ParserHelper      = context.requireCordovaModule('cordova-lib/src/cordova/metadata/parserhelper/ParserHelper'),
        ConfigParser      = context.requireCordovaModule('cordova-common').ConfigParser;

    var deferral = new Q.defer();
    var projectRoot = cordova_util.cdProjectRoot();

    var key = crypto.randomBytes(24).toString('base64');
    var iv = crypto.randomBytes(12).toString('base64');

    context.opts.platforms.filter(function(platform) {
        var pluginInfo = context.opts.plugin.pluginInfo;
        return pluginInfo.getPlatformsArray().indexOf(platform) > -1;
        
    }).forEach(function(platform) {
        var platformPath = path.join(projectRoot, 'platforms', platform);
        var platformApi = platforms.getPlatformApi(platform, platformPath);
        var platformInfo = platformApi.getPlatformInfo();
        var wwwDir = platformInfo.locations.www;

        var content = fs.readFileSync(wwwDir+"/assets/props.json", 'utf-8');

        fs.writeFileSync(wwwDir+"/assets/props.json", encryptData(content, key, iv), 'utf-8');

        if (platform == 'ios') {
            var pluginDir;
            try {
              var ios_parser = context.requireCordovaModule('cordova-lib/src/cordova/metadata/ios_parser'),
                  iosParser = new ios_parser(platformPath);
              pluginDir = path.join(iosParser.cordovaproj, 'Plugins', context.opts.plugin.id);
            } catch (err) {
              var xcodeproj_dir = fs.readdirSync(platformPath).filter(function(e) { return e.match(/\.xcodeproj$/i); })[0],
                  xcodeproj = path.join(platformPath, xcodeproj_dir),
                  originalName = xcodeproj.substring(xcodeproj.lastIndexOf(path.sep)+1, xcodeproj.indexOf('.xcodeproj')),
                  cordovaproj = path.join(platformPath, originalName);

              pluginDir = path.join(cordovaproj, 'Plugins', context.opts.plugin.id);
            }
            replaceCryptKey_ios(pluginDir, key, iv);

        } else if (platform == 'android') {
            var pluginDir = path.join(platformPath, 'src');
            replaceCryptKey_android(pluginDir, key, iv);            
        }
    });

    deferral.resolve();
    return deferral.promise;


    function replaceCryptKey_ios(pluginDir, key, iv) {
        var sourceFile = path.join(pluginDir, 'MobilityUtils.m');
        var content = fs.readFileSync(sourceFile, 'utf-8');


        content = content.replace(/kCryptKey = @".*";/, 'kCryptKey = @"' + key + '";')
                         .replace(/kCryptIv = @".*";/, 'kCryptIv = @"' + iv + '";');                         

        fs.writeFileSync(sourceFile, content, 'utf-8');
    }

    function replaceCryptKey_android(pluginDir, key, iv) {
        var sourceFile = path.join(pluginDir, 'com/rakbank/mobility/MobilityUtils.java');
        var content = fs.readFileSync(sourceFile, 'utf-8');

        content = content.replace(/CRYPT_KEY = ".*";/, 'CRYPT_KEY = "' + key + '";')
                         .replace(/CRYPT_IV = ".*";/, 'CRYPT_IV = "' + iv + '";');

        fs.writeFileSync(sourceFile, content, 'utf-8');
    }

    function encryptData(input, key, iv) {
        var cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
        var encrypted = cipher.update(input, 'utf8', 'base64') + cipher.final('base64');

        return encrypted;
    }
}