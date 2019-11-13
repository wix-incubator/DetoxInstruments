//
//  dtx_libproc.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/6/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

// iphoneOS SDK does not include libproc.h and internal includes, but the symbols exist.

#if TARGET_OS_MACCATALYST
#import <libproc.h>
#else

#ifndef dtx_libproc_h
#define dtx_libproc_h

typedef void *rusage_info_t;
extern int proc_pid_rusage(pid_t pid, int flavor, rusage_info_t *buffer) __OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0);

struct proc_fileinfo {
	uint32_t		fi_openflags;
	uint32_t		fi_status;
	off_t			fi_offset;
	int32_t			fi_type;
	uint32_t		fi_guardflags;
};

struct vinfo_stat {
	uint32_t	vst_dev;	/* [XSI] ID of device containing file */
	uint16_t	vst_mode;	/* [XSI] Mode of file (see below) */
	uint16_t	vst_nlink;	/* [XSI] Number of hard links */
	uint64_t	vst_ino;	/* [XSI] File serial number */
	uid_t		vst_uid;	/* [XSI] User ID of the file */
	gid_t		vst_gid;	/* [XSI] Group ID of the file */
	int64_t		vst_atime;	/* [XSI] Time of last access */
	int64_t		vst_atimensec;	/* nsec of last access */
	int64_t		vst_mtime;	/* [XSI] Last data modification time */
	int64_t		vst_mtimensec;	/* last data modification nsec */
	int64_t		vst_ctime;	/* [XSI] Time of last status change */
	int64_t		vst_ctimensec;	/* nsec of last status change */
	int64_t		vst_birthtime;	/*  File creation time(birth)  */
	int64_t		vst_birthtimensec;	/* nsec of File creation time */
	off_t		vst_size;	/* [XSI] file size, in bytes */
	int64_t		vst_blocks;	/* [XSI] blocks allocated for file */
	int32_t		vst_blksize;	/* [XSI] optimal blocksize for I/O */
	uint32_t	vst_flags;	/* user defined flags for file */
	uint32_t	vst_gen;	/* file generation number */
	uint32_t	vst_rdev;	/* [XSI] Device ID */
	int64_t		vst_qspare[2];	/* RESERVED: DO NOT USE! */
};

struct vnode_info {
	struct vinfo_stat	vi_stat;
	int			vi_type;
	int			vi_pad;
	fsid_t			vi_fsid;
};

struct vnode_info_path {
	struct vnode_info	vip_vi;
	char			vip_path[MAXPATHLEN];	/* tail end of it  */
};

struct proc_fdinfo {
	int32_t			proc_fd;
	uint32_t		proc_fdtype;
};
struct vnode_fdinfowithpath {
	struct proc_fileinfo	pfi;
	struct vnode_info_path	pvip;
};

#define PROX_FDTYPE_VNODE	1
#define PROC_PIDLISTFDS			1
#define PROC_PIDLISTFD_SIZE		(sizeof(struct proc_fdinfo))
#define PROC_PIDFDVNODEPATHINFO		2
#define PROC_PIDFDVNODEPATHINFO_SIZE	(sizeof(struct vnode_fdinfowithpath))
int proc_pidinfo(pid_t pid, int flavor, uint64_t arg,  void *buffer, int buffersize);
int proc_pidfdinfo(pid_t pid, int fd, int flavor, void * buffer, int buffersize);


#endif /* dtx_libproc_h */

#endif
