souce .env

fly deploy --remote-only \
  --vm-cpu-kind "shared" \
  --vm-cpus $PALMETTO_VCPU_TYPE \
  --vm-memory 4096