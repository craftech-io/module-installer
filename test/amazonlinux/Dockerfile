FROM amazonlinux
MAINTAINER Module <info@module.io>

RUN yum install -y curl sudo

COPY . /test

CMD ["echo", "This container is used for testing. Consider running one of the test scripts under the /test folder."]
