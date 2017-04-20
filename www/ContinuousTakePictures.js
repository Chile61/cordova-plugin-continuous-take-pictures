
var exec = cordova.require("cordova/exec");

var takePicturesInProgress = false;


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

    if (config instanceof Array) {
        // do nothing
    } else {
        if (typeof (config) === 'object') {
            config = [config];
        } else {
            config = [];
        }
    }

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

    // if (takePicturesInProgress) {
    //     errorCallback('TakePictures is already in progress');
    //     return;
    // }

    takePicturesInProgress = true;

    exec(
        function (result) {
            takePicturesInProgress = false;
            successCallback(result);
        },
        function (error) {
            takePicturesInProgress = false;
            errorCallback(error);
        },
        'ContinuousTakePictures',
        'ContinuousTakePictures',
        config
    );
};


var ContinuousTakePictures = new ContinuousTakePictures();
module.exports = ContinuousTakePictures;
