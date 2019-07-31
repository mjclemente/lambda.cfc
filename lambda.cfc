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

    var invokeRequest = createObject( 'java', 'com.amazonaws.services.lambda.model.InvokeRequest').init();
    invokeRequest.setFunctionName( arn );

    var jsonPayload = parsePayload( payload );

    if ( jsonPayload.len() )
      invokeRequest.setPayload( jsonPayload );

    var response = lambda.invoke( invokeRequest );

    return decodeResponse( response );
  }

  private any function lambdaClient( required string arn ) {
    var awsCredentials = createObject( 'java', 'com.amazonaws.auth.BasicAWSCredentials').init( variables.accessKey, variables.secretKey );
    var awsStaticCredentialsProvider = createObject( 'java','com.amazonaws.auth.AWSStaticCredentialsProvider' ).init( awsCredentials );
    return buildFromArn( arn, awsStaticCredentialsProvider );
  }

  /**
  * @hint Takes an arn and combines it with the credentials to return the Lambda client
  */
  private any function buildFromArn( arn, awsStaticCredentialsProvider ) {
    var arnComponents = parseArn( arn );
    var awsRegion = arnComponents.region;

    return createObject( 'java', 'com.amazonaws.services.lambda.AWSLambdaClientBuilder').standard().withCredentials( awsStaticCredentialsProvider ).withRegion( awsRegion ).build();
  }

  /**
  * @hint The payload returned from a Lambda function invocation in the Java SDK is always a Java binary stream. As such, it needs to be decoded into a string of characters.
  * @response must be the object returned by the Lambda object's invoke() method
  */
  private string function decodeResponse( required any response ) {
    var charset = createObject( 'java', 'java.nio.charset.Charset' ).forName( 'UTF-8' );
    var charsetDecoder = charset.newDecoder();

    return charsetDecoder.decode( response.getPayload() ).toString();
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