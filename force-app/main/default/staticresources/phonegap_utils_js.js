/****************************************************************
                        Added to RK base RMIS product as 05/29/2013        
*******************************************************************/
function takePic() {
	        navigator.camera.getPicture(onPicSuccess, onPicFail, { quality: 50});
	    }
	    
	    function chooseExistingPic() {
	       navigator.camera.getPicture(onPicSuccess, onPicFail, { quality: 50, sourceType: Camera.PictureSourceType.PHOTOLIBRARY });
	    }
	    
	    function recordAudio() {
            navigator.device.capture.captureAudio(onCaptureSuccess, onCaptureError, {duration: 600});
        }
        
        function recordVideo() {
            navigator.device.capture.captureVideo(onCaptureSuccess, onCaptureError, {duration: 600});
        }
	     
	    function onPicSuccess(imageData) {
	        var recId =  "{!IntakeIncident.Id}";
	        ThreadControllerExt.saveIncidentImage(imageData, recId,
	            function(res,event){
	                $j('#attachPic').src = "data:image/jpeg;base64," + imageData;
	            });
	    }
	    function onPicFail(message) {
	        console.log("Pic failed: " + JSON.stringify(message));
	    }
	    
	    function onCaptureSuccess(mediaFiles) {
	        var i, len;
	        for (i = 0, len = mediaFiles.length; i < len; i += 1) {
	            uploadFile(mediaFiles[i]);
	        }       
	    }
	    
	    function onCaptureError(error) {
	        var msg = 'An error occurred during capture: ' + error.code + ' ' +CaptureError.CAPTURE_INTERNAL_ERR+' '+CaptureError.CAPTURE_APPLICATION_BUSY+' '+CaptureError.CAPTURE_INVALID_ARGUMENT+' '+CaptureError.CAPTURE_NO_MEDIA_FILES+' '+CaptureError.CAPTURE_NOT_SUPPORTED;
	        navigator.notification.alert(msg, null, 'Uh oh!');
	    }
	    
        function uploadFile(mediaFile) {
	        var recId = "{!IntakeIncident.Id}";
	        
	        var reader = new FileReader();
	        reader.onload = function(evt) {
	        console.log("read success");
	        console.log(evt.target.result);
	        resultArr = evt.target.result.split(',');
	           ThreadControllerExt.saveIncidentAudio(resultArr[1], recId,
               function(res, event) {
               
               });
	        };
	        reader.readAsDataURL(mediaFile.fullPath)
	    }