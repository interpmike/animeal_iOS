import { AmplifyAuthCognitoStackTemplate } from '@aws-amplify/cli-extensibility-helper';

export function override(resources: AmplifyAuthCognitoStackTemplate) {
  resources.userPool.autoVerifiedAttributes = ['email', 'phone_number'];
  resources.userPool.smsConfiguration = {
    externalId: '34a848dc-25e0-4385-9cf8-380f18bad969',
    snsCallerArn: 'arn:aws:iam::027735239009:role/service-role/animeal-sns-role',
  };

  const amplifyMetaJson = require('../../../amplify-meta.json');
  const accountId = amplifyMetaJson.providers.awscloudformation.StackId.split(':').slice(-2, -1).pop();
  const region = amplifyMetaJson.providers.awscloudformation.StackId.split(':').slice(-3, -2).pop();

  resources.userPool.emailConfiguration = {
    emailSendingAccount: 'DEVELOPER',
    from: 'no-reply@animeal.ge',
    sourceArn: `arn:aws:ses:${region}:${accountId}:identity/animeal.ge`,
  };

  const myCustomAttribute = [];
  if (!resources.userPool.schema) {
    resources.userPool.schema = [];
  }
  resources.userPool.schema = [...(resources.userPool.schema as any[]), ...myCustomAttribute];
}