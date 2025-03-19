/**
* lambda.cfc
* Copyright 2018-2019 Matthew Clemente, Brian Klaas
* Licensed under MIT
*/
component {

  public any function init(
    required string accessKey,
    required string secretKey,
    string defaultArn = '' ) {

    variables.accessKey = accessKey;
    variables.secretKey = secretKey;
    variables.defaultArn = defaultArn;

    return this;
  }

  // For reference - full Java API reference for AWS SDK: https://sdk.amazonaws.com/java/api/latest/index.html
  // Lambda: https://sdk.amazonaws.com/java/api/latest/software/amazon/awssdk/services/lambda/package-summary.html

  /**
  * @hint Calls the Lambda function specified by the default ARN, passing in the payload. You must set the default ARN in order to use this.
  * @payload Can be passed in as JSON, an array, or a struct. Structs and arrays will be converted to JSON, as required by Lambda
  */
  public string function invoke( any payload = {} ) {
    if ( !len( variables.defaultArn ) )
      throw( message = 'Default Lambda ARN missing', detail = 'Unable to call #GetFunctionCalledName()#() without a default Lambda ARN. You can set the default ARN on init() or manually, via setDefaultArn().' );

    return invokeLambda( arn = variables.defaultArn, payload = payload );
  }

  /**
  * @hint Calls the Lambda function specified by the ARN, passing in the payload
  * @payload Can be passed in as JSON, an array, or a struct. Structs and arrays will be converted to JSON, as required by Lambda
  */
  public string function invokeFunction( required string arn, any payload = {} ) {
    return invokeLambda( arn = arn, payload = payload );
  }

  /**
  * @hint Handles the actual interaction with Lambda for the public methods.
  */
  private string function invokeLambda( required string arn, required any payload ) {

    var lambda = lambdaClient( arn = arn );

    var invokeRequest = createObject( 'java', 'software.amazon.awssdk.services.lambda.model.InvokeRequest').builder();
    invokeRequest.functionName( arn );

    var jsonPayload = parsePayload( payload );

    if ( jsonPayload.len() ){
      //https://sdk.amazonaws.com/java/api/latest/software/amazon/awssdk/core/SdkBytes.html
      var SdkBytes = createObject( 'java', 'software.amazon.awssdk.core.SdkBytes' ).fromUtf8String( jsonPayload );
      invokeRequest.payload( SdkBytes );
    }
    var test = lambda.build();
    var response = test.invoke( invokeRequest.build() );

    return decodeResponse( response );
  }

  private any function lambdaClient( required string arn ) {
    // https://sdk.amazonaws.com/java/api/latest/software/amazon/awssdk/auth/credentials/AwsBasicCredentials.html
    var awsCredentials = createObject( 'java', 'software.amazon.awssdk.auth.credentials.AwsBasicCredentials').create( variables.accessKey, variables.secretKey );
    // https://sdk.amazonaws.com/java/api/latest/software/amazon/awssdk/auth/credentials/StaticCredentialsProvider.html
    var awsStaticCredentialsProvider = createObject( 'java','software.amazon.awssdk.auth.credentials.StaticCredentialsProvider' ).create( awsCredentials );
    return buildFromArn( arn, awsStaticCredentialsProvider );
  }

  /**
  * @hint Takes an arn and combines it with the credentials to return the Lambda client
  */
  private any function buildFromArn( arn, awsStaticCredentialsProvider ) {
    var arnComponents = parseArn( arn );
    // https://sdk.amazonaws.com/java/api/latest/software/amazon/awssdk/regions/Region.html
    var awsRegion = createObject('java', 'software.amazon.awssdk.regions.Region').of(arnComponents.region);

    return createObject( 'java', 'software.amazon.awssdk.services.lambda.LambdaClient').builder().credentialsProvider( awsStaticCredentialsProvider ).region( awsRegion );
  }

  /**
  * @hint The payload returned from a Lambda function invocation in the Java SDK is always a Java binary stream. As such, it needs to be decoded into a string of characters.
  * @response must be the object returned by the Lambda object's invoke() method
  */
  private string function decodeResponse( required any response ) {
    var charset = createObject( 'java', 'java.nio.charset.Charset' ).forName( 'UTF-8' );
    var charsetDecoder = charset.newDecoder();
    // https://sdk.amazonaws.com/java/api/latest/software/amazon/awssdk/services/lambda/model/InvokeResponse.html
    return response.payload().asUtf8String();
  }

  /**
  * @hint ensures the payload passed to Lambda is JSON
  */
  private string function parsePayload( required any payload ) {
    if ( isStruct( payload ) || isArray( payload ) )
      return serializeJson( payload );
    else if ( isJson( payload ) )
      return payload;
    else
      return '';
  }


  /**
  * @hint Parses an Amazon Resource Name (ARN) and returns its component parts as an object.
  * This follows the general format of ARNs outlined by Amazon (http://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html), but does not fully account for all possible formats
  * Derived from https://gist.github.com/gene1wood/5299969edc4ef21d8efcfea52158dd40
  */
  private struct function parseArn( required string arn ) {
    var elements = arn.listToArray( ':', true );
    var result = {
      'original' : arn,
      'arn' : elements[1],
      'partition' : elements[2],
      'service' : elements[3],
      'region' : elements[4],
      'account' : elements[5]
    };

    if ( elements.len() >= 7 ) {
      result[ 'resourcetype' ] = elements[6];
      result[ 'resource' ] = elements[7];
    } else if ( !elements[6].find( '/' ) ) {
      result[ 'resource' ] = elements[6];
      result[ 'resourcetype' ] = '';
    } else {
      result[ 'resourcetype' ] = elements[6].listFirst( '/' );
      result[ 'resource' ] = elements[6].listRest( '/' );
    }

    return result;
  }

}
