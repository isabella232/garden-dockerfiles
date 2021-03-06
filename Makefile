all: with-volume garden-ci tutu
.PHONY: push garden-ci with-volume empty zip-bomb dev-vm fifteen-point-five tutu

push:
	docker push cfgarden/with-volume
	docker push cfgarden/garden-ci
	docker push cfgarden/empty
	docker push cfgarden/zip-bomb
	docker push cfgarden/tutu
	docker push cfgarden/hello

ROOTFS_DIR=garden-ci/rootfs
ASSETS_DIR=garden-ci/assets
ASSETS=${ASSETS_DIR}/busybox.tar ${ASSETS_DIR}/docker_registry_v2.tar ${ASSETS_DIR}/fuse.tar

${ASSETS_DIR}/busybox.tar:
	docker build -t cfgarden/busybox --rm ${ROOTFS_DIR}/busybox
	docker run --name busybox cfgarden/busybox
	docker export -o ${ASSETS_DIR}/busybox.tar busybox
	docker rm -f busybox

${ASSETS_DIR}/fuse.tar: ${ROOTFS_DIR}/fuse/Dockerfile
	docker build -t cfgarden/fuse --rm ${ROOTFS_DIR}/fuse
	docker run --name fuse cfgarden/fuse
	docker export -o ${ASSETS_DIR}/fuse.tar fuse
	docker rm -f fuse

${ASSETS_DIR}/docker_registry_v2.tar:
	# spin up a local docker registry
	docker run -d -p "5000:5000" -e "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/opt/docker-registry" --name docker_registry_v2 registry:2.6.2

	# push busybox to our local registry
	docker pull busybox
	docker tag busybox localhost:5000/busybox
	docker push localhost:5000/busybox

	# export registry iamge as a tar
	docker export -o ${ASSETS_DIR}/docker_registry_v2.tar docker_registry_v2
	docker rm -f docker_registry_v2

garden-ci: ${ASSETS} garden-ci/Dockerfile
	docker build -t cfgarden/garden-ci --rm garden-ci

with-volume: with-volume/Dockerfile
	docker build -t cfgarden/with-volume --rm with-volume

with-process-env: with-process-env/Dockerfile
	docker build -t cfgarden/with-process-env --rm with-process-env

tutu:
	docker build -t cfgarden/tutu --rm tutu

iamthebomb:
	docker build -t cfgarden/iamthebomb --rm zip-bomb

hello: hello/Dockerfile
	docker build -t cfgarden/hello --rm hello
