#!/bin/bash

#Sample Usage: pushToBintray.sh username api_key repo package_name package-path package_version

set -x
API=https://api.bintray.com

BINTRAY_USER=$1
BINTRAY_API_KEY=$2
BINTRAY_REPO=$3
PCK_NAME=$4
PACKAGE=$5
PACKAGE_DESCRIPTOR=bintray-package.json
PCK_VERSION=$6
VERSION_DESCRIPTOR=bintray-package-version.json


main() {
  CURL="curl -u${BINTRAY_USER}:${BINTRAY_API_KEY} -H Content-Type:application/json -H Accept:application/json"
  if (check_package_exists); then
    echo "The package ${PCK_NAME} does not exist. It will be created"
    create_package
  fi

  if (check_version_exists); then
    echo "The version ${PCK_VERSION} does not exist. It will be created"
    create_version
  fi
  deploy_package
}

check_package_exists() {
  echo "Checking if package ${PCK_NAME} exists..."

  if [ $(${CURL} --write-out %{http_code} --silent --output /dev/null -X GET ${API}/packages/${BINTRAY_USER}/${BINTRAY_REPO}/${PCK_NAME}) -eq "200" ]; then
      echo "package already exists"
      return 1
  else
      return 0

  fi
}

check_version_exists() {
  echo "Checking if version ${PCK_VERSION} exists..."

  if [ $(${CURL} --write-out %{http_code} --silent --output /dev/null -X GET ${API}/packages/${BINTRAY_USER}/${BINTRAY_REPO}/${PCK_NAME}/versions/${PCK_VERSION}) -eq "200" ]; then
      echo "version already exists"
      return 1
  else
      return 0
  fi
}

create_package() {
  echo "Creating package ${PCK_NAME}..."
  if [ -f "${PACKAGE_DESCRIPTOR}" ]; then
    data="@${PACKAGE_DESCRIPTOR}"
  else
    data="{
    \"name\": \"${PCK_NAME}\",
    \"desc\": \"auto\",
    \"desc_url\": \"auto\",
    \"labels\": [\"RackHD\"]
    }"
  fi

  if [ $(${CURL} --write-out %{http_code} --silent --output /dev/null -X POST ${API}/packages/${BINTRAY_USER}/${BINTRAY_REPO}/ --data "${data}") -eq "201" ]; then
    echo "Succeed to create package ${PCK_NAME}."
  else
    echo "Failed to create package ${PCK_NAME}."
    exit 1
  fi

}

create_version() {
  echo "Creating version ${PCK_VERSION}..."
  if [ -f "${VERSION_DESCRIPTOR}" ]; then
    data="@${VERSION_DESCRIPTOR}"
  else
    data="{
    \"name\": \"${PCK_VERSION}\",
    \"desc\": \"This version ...\"
    }"
  fi

  echo "${CURL} -X POST ${API}/packages/${BINTRAY_USER}/${BINTRAY_REPO}/${PCK_NAME}/versions --data \"${data}\""
  if [ $(${CURL} --write-out %{http_code} --silent --output /dev/null -X POST ${API}/packages/${BINTRAY_USER}/${BINTRAY_REPO}/${PCK_NAME}/versions --data "${data}") -eq "201" ];then
    echo "Succeed to create version ${PCK_VERSION}."
  else
    echo "Failed to create version ${PCK_VERSION}."
    exit 1
  fi
}

deploy_package() {
  if (upload_content); then
    echo "Publishing ${PACKAGE}..."
    echo "${CURL} -X POST ${API}/content/${BINTRAY_USER}/${BINTRAY_REPO}/${PCK_NAME}/${PCK_VERSION}/publish"
    if [ $(${CURL} --write-out %{http_code} --silent --output /dev/null -X POST ${API}/content/${BINTRAY_USER}/${BINTRAY_REPO}/${PCK_NAME}/${PCK_VERSION}/publish) -eq "200" ]; then
      echo "Package ${PACKAGE} published"
    else
      echo "[SEVERE] First you should upload your package ${PACKAGE}"
    fi
  fi
}

upload_content() {
  echo "Uploading ${PACKAGE}..."

  if [ $(${CURL} --write-out %{http_code} --silent --output /dev/null -H X-Bintray-Debian-Distribution:wheezy -H X-Bintray-Debian-Component:main -H X-Bintray-Debian-Architecture:i386,amd64 -H X-Bintray-Override:1 -T ${PACKAGE} ${API}/content/${BINTRAY_USER}/${BINTRAY_REPO}/${PCK_NAME}/${PCK_VERSION}/ ) -eq "201" ]; then
      echo "Package ${PACKAGE} uploaded"
      return 0
  else
      echo "Failed to upload package ${PACKAGE}"
      return 1
  fi
}

main "$@"
