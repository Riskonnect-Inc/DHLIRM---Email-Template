({
	remoteCall: function(cmp, remoteName, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            var remoteRequest = cmp.get("c." + remoteName);

            remoteRequest.setParams(params);

            remoteRequest.setCallback(this,
                function(response) {
                    switch (response.getState()) {
                        case "SUCCESS":
                            var responseWrapperJSON = response.getReturnValue();

                            var responseWrapper = JSON.parse(responseWrapperJSON);

                            if (responseWrapper.error) {
                                reject(responseWrapper.error);
                            } else {
                                resolve(responseWrapper.payload);
                            }

                            break;
                        case "ERROR":
                            reject(response.getError());
                            break;
                    }
                }
            );

            $A.enqueueAction(remoteRequest);
        }));
    }
})