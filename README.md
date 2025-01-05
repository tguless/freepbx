Here is why this repository exists:

1. Running FreePBX in Rosetta emulation on MacOS is not advised as VOIP workloads can be resource intensive as they need to transcode audio etc. 

2. Running FreePBX on a MacOS through an ARM64 based Debian VM is not as light weight as running a similar docker container - i.e. memory would have to be dedicated for highest load / worst case scenarios.  

3. This project opens up the opportunity of running on inexpensive AWS [Graviton](https://aws.amazon.com/ec2/graviton/) servers. It on inexpensive arm64 based cloud hosted VMs 

4. This project also opens up the opportunity of running FreePBX on a Raspberry pi.

5. FreePBX [one click installer](https://sangomakb.atlassian.net/wiki/spaces/FP/pages/230326391/FreePBX+17+Installation) has to be run on Debian OS (Ubuntu and other Debian derivatives are ok I believe). 

6. FreePBX [one click installer](https://sangomakb.atlassian.net/wiki/spaces/FP/pages/230326391/FreePBX+17+Installation) will not run an ARM64 compiled Debian. 

7. The [more manual install script](https://sangomakb.atlassian.net/wiki/spaces/FP/pages/10682545/How+to+Install+FreePBX+17+on+Debian+12+with+Asterisk+21) will run on any arm64 based Linux but not MacOS

8. There was no arm64 compiled docker container running FreePBX that was set up for both arm64 and amd64.

9. There was [a Debian 12.8 (bookworm) docker image](https://hub.docker.com/layers/library/debian/bookworm/images/sha256-5d99d20795032654a4d76a464cbd9733a5f0fc3911b6f2a36c1d51211b104afe) that was arm64 native which we could use as a base and apply the required asterisk and FreePBX changes on top of by following [the more manual install script](https://sangomakb.atlassian.net/wiki/spaces/FP/pages/10682545/How+to+Install+FreePBX+17+on+Debian+12+with+Asterisk+21) 

10. There was also several example Dockerfiles that got FreePBX dependencies installed on a base image but almost all generated errors when base image was changed to arm64, and they all ran older versions of Asterisk and FreePBX

   | Source                                                       | OS                                                           | FreePBX | Last Update  | Asterisk                                                     | My Version                       |
   | ------------------------------------------------------------ | ------------------------------------------------------------ | ------- | ------------ | ------------------------------------------------------------ | -------------------------------- |
   | [nestorlora/izdock-izpbx](https://github.com/nestorlora/izdock-izpbx) | Centos                                                       | 15      | Jan 29, 2021 | 18.2                                                         | tried with rockylinux            |
   | [mlan/docker-asterisk](https://github.com/mlan/docker-asterisk) | alpine:latest                                                | N/A     | Dec 7, 2024  | from alpine:latest repo                                      | did not try as only had asterisk |
   | [tiredofit/freepbx](https://github.com/tiredofit/docker-freepbx/tree/15) | [debian (buster - bookworm available)](https://github.com/tiredofit/docker-debian) | 15      | May 31, 2022 | 17.94                                                        | should try - more robust         |
   | [flaviostutz/freepbx](https://github.com/flaviostutz/freepbx) | debian 10.3                                                  | 15      | Sep 20, 2022 | [flaviostutz/asterisk](https://github.com/flaviostutz/asterisk)<br />17.9.3 | this repo - working              |

   

   