FROM cockroachdb/cockroach:latest

# Install bind-utils for dig (for troubleshooting, can be removed)
RUN microdnf install bind-utils procps-ng && \
    microdnf clean all

# Expose ports
EXPOSE ${PALMETTO_SQL_PORT} ${PALMETTO_RPC_PORT} 8080

# Copy the scripts to the container
ADD ./.sh/format-seeds.sh /cockroach/format-seeds.sh
RUN chmod +x /cockroach/format-seeds.sh
ADD ./.sh/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Set the entrypoint
ENTRYPOINT [ "/docker-entrypoint.sh" ]