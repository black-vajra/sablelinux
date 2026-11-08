#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/xattr.h>

int main(int argc, char **argv)
{
    char path[512], link[512], value[32];
    struct stat probe, alias;
    const char expected[] = "preserved";

    if (argc != 3)
        return 2;

    int path_len = snprintf(path, sizeof path,
        "%s/usr/share/sable-install-test/metadata", argv[1]);
    int link_len = snprintf(link, sizeof link, "%s.link", path);
    if (path_len < 0 || (size_t)path_len >= sizeof path ||
        link_len < 0 || (size_t)link_len >= sizeof link)
        return 2;

    if (lstat(path, &probe) || lstat(link, &alias)) {
        perror("metadata fixture stat");
        return 1;
    }
    if (!S_ISREG(probe.st_mode) || probe.st_uid != 12345 ||
        probe.st_gid != 23456 || (probe.st_mode & 07777) != 0640) {
        fprintf(stderr, "%s: expected regular file with UID 12345, GID 23456 and mode 0640\n",
            argv[2]);
        return 1;
    }
    if (probe.st_dev != alias.st_dev || probe.st_ino != alias.st_ino ||
        probe.st_nlink != 2) {
        fprintf(stderr, "%s: hard-link identity or count mismatch\n", argv[2]);
        return 1;
    }

    ssize_t size = getxattr(path, "user.sable_install_test", value, sizeof value);
    if (size < 0) {
        perror("user.sable_install_test");
        return 1;
    }
    if ((size_t)size != sizeof expected - 1 ||
        memcmp(value, expected, sizeof expected - 1) != 0) {
        fprintf(stderr, "%s: user xattr value mismatch\n", argv[2]);
        return 1;
    }

    /* Linux VFS capability revision 2, effective flag and CAP_NET_RAW
     * permitted, with all other capability bits clear. */
    const unsigned char expected_cap[20] = {
        0x01, 0x00, 0x00, 0x02, 0x00, 0x20
    };
    int cap_len = snprintf(path, sizeof path,
        "%s/usr/share/sable-install-test/capability-probe", argv[1]);
    if (cap_len < 0 || (size_t)cap_len >= sizeof path)
        return 2;

    size = lgetxattr(path, "security.capability", value, sizeof value);
    if (size < 0) {
        fprintf(stderr, "%s: capability probe: ", argv[2]);
        perror("security.capability");
        return 1;
    }
    if ((size_t)size != sizeof expected_cap ||
        memcmp(value, expected_cap, sizeof expected_cap) != 0) {
        fprintf(stderr, "%s: security.capability bytes mismatch\n", argv[2]);
        return 1;
    }

    printf("SABLE_INSTALL_CAPABILITY_PASS %s\n", argv[2]);
    printf("SABLE_INSTALL_METADATA_PASS %s\n", argv[2]);
    return 0;
}
