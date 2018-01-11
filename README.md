# lambda.cfc
Call AWS Lambda functions directly from your CFML code... with a little help from Java.

### Acknowledgements

The core interactions with AWS used in this project are derived from projects and demos by [brianklaas](https://github.com/brianklaas), particularly [AWS Playbox](https://github.com/brianklaas/awsPlaybox).

### Requirements

This component depends on the .jar files contained in the `/lib` directory. All of these files can be downloaded from https://aws.amazon.com/sdk-for-java/ Files other than the actual SDK .jar itself can be found in the `/third-party` directory within the SDK download.

There are two ways that you can include them in your project.

1. Include the files in your `<cf_root>/lib` directory. You will need to restart the ColdFusion server.
2. Use `this.javaSettings` in your Application.cfc to load the .jar files. Just specify the directory that you place them in; something along the lines of

	```cfc
  	this.javaSettings = {
    	loadPaths = [ '.\path\to\jars\' ]
  	};
	```