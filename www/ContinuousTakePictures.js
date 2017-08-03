
var exec = cordova.require("cordova/exec");

function ContinuousTakePictures() {


}

/**
 * Read code from scanner.
 *
 * @param {Function} successCallback 
 * @param {Function} errorCallback
 * @param config
 */
ContinuousTakePictures.prototype.takePictures = function (successCallback, errorCallback, config) {
    config = config || {};

    var args = [];
    args[0] = config.dir || "tmp";
    args[1] = config.coverTpls || "";
    args[2] = config.isDrawing || false;
    args[3] = config.isNeedRecord || false;


    if (errorCallback == null) {
        errorCallback = function () {
        };
    }

    if (typeof errorCallback != "function") {
        console.log("ContinuousTakePictures.scan failure: failure parameter not a function");
        return;
    }

    if (typeof successCallback != "function") {
        console.log("ContinuousTakePictures.scan failure: success callback parameter must be a function");
        return;
    }

    exec(
        function (result) {
            successCallback(JSON.parse(result));
        },
        function (error) {
            errorCallback(error);
        },
        'ContinuousTakePictures',
        'ContinuousTakePictures',
        args
    );
};


var ContinuousTakePictures = new ContinuousTakePictures();
module.exports = ContinuousTakePictures;
