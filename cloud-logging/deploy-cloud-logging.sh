#!/bin/bash

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ -z "$PROJECT" ]
then
echo "No PROJECT variable set"
exit
fi


if [ -z "$APIGEE_ENV" ]
then
echo "No APIGEE_ENV variable set"
exit
fi

if [ -z "$APIGEE_HOST" ]
then
echo "No APIGEE_HOST variable set"
exit
fi

TOKEN=$(gcloud auth print-access-token)
SA_NAME=apigee-proxy-service-account

echo "Installing apigeecli"
curl -s https://raw.githubusercontent.com/apigee/apigeecli/master/downloadLatest.sh | bash
export PATH=$PATH:$HOME/.apigeecli/bin

echo "Creating API Proxy Service Account and granting Cloud Logging role to it"
gcloud iam service-accounts create $SA_NAME
gcloud projects add-iam-policy-binding $PROJECT \
    --member="serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"


echo "Importing and Deploying Apigee cloud-logging proxy..."
zip -r cloud-logging.zip apiproxy
REV=$(apigeecli apis import -f cloud-logging.zip --org $PROJECT --token $TOKEN --disable-check | jq ."revision" -r)
apigeecli apis deploy --wait --name cloud-logging --ovr --rev $REV --org $PROJECT --env $APIGEE_ENV --token $TOKEN
