# lambda.cfc
Call AWS Lambda functions directly from your CFML code... with a little help from Java.

## Table of Contents

- [Acknowledgements](#acknowledgements)
- [Getting Started](#getting-started)
- [Setting a Default Lambda Function](#setting-a-default-lambda-function)
- [Reference Manual](#reference-manual)
- [A Note on Permissions](#a-note-on-permissions)
- [Requirements](#requirements)

### Acknowledgements

The core interactions with AWS used in this project are derived from projects and demos by [brianklaas](https://github.com/brianklaas), particularly [AWS Playbox](https://github.com/brianklaas/awsPlaybox).

### Getting Started

*This assumes some degree of familiarity with AWS services, permissions, etc. If you're not familiar with AWS, this is going to sound like a complicated mess, but it's really pretty straightforward.*

In order to be initialized, the component requires a [properly permissioned user's](#a-note-on-permissions) AccessKey and SecretKey (there's an optional third parameter for [setting a default Lambda function]((#setting-a-default-lambda-function))):

```cfc
lambda = new lambda( accessKey = xxx, secretKey = xxx );
```

The component can then be used to invoke Lambda functions. This is done via the `invokeFunction()` method, which requires the ARN of the Lambda function being invoked, with an optional second parameter for a payload of arguments:

```cfc
arn = 'arn:aws:lambda:us-east-1:123456789098:function:yourArn';
payload = {
  "variable" : value,
  "other" : value2
};
result = lambda.invokeFunction( arn, payload );
```

### Setting a Default Lambda Function

In some cases, you may be creating objects intended to invoke a single Lambda function. Rather than passing in the ARN every time, you can include it as the `defaultArn` during initialization:

```cfc
lambda = new lambda(
  accessKey = xxx,
  secretKey = xxx,
  defaultArn = 'arn:aws:lambda:us-east-1:123456789098:function:yourArn' );
```

Setting a default ARN enables you to use the cleaner syntax of the `invoke()` method. You don't need to include the ARN; it will call the Lambda function specified by the default ARN, passing in the optional payload of arguments:

```cfc
payload = {
  "variable" : value
};
//invokes the function specified by the default ARN
result = lambda.invoke( payload );
```

### Reference Manual

#### `invoke( any payload = {} )`

Calls the Lambda function specified by the default ARN, passing in the payload. You must set the default ARN in order to use this.

The payload can be passed in as JSON, an array, or a struct. Structs and arrays will be converted to JSON, as required by Lambda

#### `invokeFunction( required string arn, any payload = {} )`

Calls the Lambda function specified by the ARN parameter, passing in the payload.

The payload can be passed in as JSON, an array, or a struct. Structs and arrays will be converted to JSON, as required by Lambda

#### `setDefaultArn( string arn = '' )`

Method for setting the default ARN manually, after `init()`.

### A Note on Permissions

In order to use this component, you will need an IAM User with, at minimum, `lambda:InvokeFunction` permission (which shouldn't come as a surprise, given that its sole purpose is to invoke a Lambda function). This is easily set up by applying the `AWSLambdaRole` policy to the desired user. Other more expansive policies could also be used.

### Requirements

This component depends on the .jar files contained in the `/lib` directory. These were generated using Maven, as described [in the Github repository for AWS SDK for Java 2.0](https://github.com/aws/aws-sdk-java-v2?tab=readme-ov-file#using-the-sdk). They are for version 2.32.2 of the SDK.

There are two ways that you can include them in your project.

1. Include the files in your `<cf_root>/lib` directory. You will need to restart the ColdFusion server.
2. Use `this.javaSettings` in your Application.cfc to load the .jar files. Just specify the directory that you place them in; something along the lines of

  ```cfc
    this.javaSettings = {
      loadPaths = [ '.\path\to\jars\' ]
    };
  ```

#### Lucee CFML Specific Jar Option

When using `lambda.cfc` with Lucee CFML, you have the option to provide the directory that contains the AWS Java SDK jar files when initializing the object:

```cfc
  classpath = expandPath( "/path/to/aws_java_sdk/jars" );

  // will use the AWS Java SDK jars in the class path provided
  lambda = new path.to.lambda( accessKey = xxx, secretKey = xxx, classPath = classpath );
```

This can be helpful if you want to avoid using `this.javaSettings` (for example, because of [LDEV-2516](https://luceeserver.atlassian.net/browse/LDEV-2516)).

To be clear, this approach 1) is not possible with Adobe ColdFusion, 2) is not required for Lucee, and 3) when used with Lucee, means that you do *not* need to add the .jars to your `<cf_root>/lib` directory or `this.javasettings`.
