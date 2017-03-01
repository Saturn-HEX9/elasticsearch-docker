#!/bin/bash -eux
#
# Copyright 2017 Google Inc.
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
#
# Required environment variables:
#   PROJECT: Your GCP project where the GCR bucket resides.
#   BUCKET: A GCS bucket (typically in the GCP project above) for
#     storing cloudbuild logs and intermediates.
#   KEYFILE: Absolute path to gcloud key file for authenticating your
#     service account. Make sure that the service account has write
#     access to your GCS (and GCR) buckets.
#   GCLOUD: Absolute path to gcloud binary, or a .tar.gz file
#     containing the gcloud application.
#   WORKINGDIR: Typically set to ".". This variable allows the script to
#     change to the correct working directory when executed in a different
#     build environment.

# Ensure all required env vars are supplied
for var in PROJECT BUCKET KEYFILE GCLOUD WORKINGDIR; do
  val=$(eval "echo \$$var")
  if [ -z "$val" ]; then
    echo "$var env variable is required"
    exit 1
  fi
done

cd "$WORKINGDIR"

if [[ "$GCLOUD" == *.tar.gz ]]; then
  # Extract the gcloud binary out of the tarball
  tar -xzf "$GCLOUD" -C .
  GCLOUD="google-cloud-sdk/bin/gcloud"
fi

# Setup auth and update gcloud
$GCLOUD auth activate-service-account --key-file=$KEYFILE
$GCLOUD config set project $PROJECT
$GCLOUD components install alpha -q
$GCLOUD components update -q

# Run the cloud build
$GCLOUD alpha container builds create . \
  --config=cloudbuild.yaml \
  --verbosity=info \
  --gcs-source-staging-dir="gs://$BUCKET/staging" \
  --gcs-log-dir="gs://$BUCKET/logs"