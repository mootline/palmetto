FROM cockroachdb/cockroach:latest

# Install bind-utils for dig (for troubleshooting, can be removed)
RUN microdnf install bind-utils procps-ng && \
    microdnf clean all
    
# Create a simple shell script that waits
COPY .sh/wait.sh /wait.sh
RUN chmod +x /wait.sh

# Use the shell script as the ENTRYPOINT
ENTRYPOINT ["/wait.sh"]