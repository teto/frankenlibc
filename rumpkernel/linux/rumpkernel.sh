#!/bin/sh

rumpkernel_buildrump()
{
./buildrump/buildrump.sh \
	-V RUMP_CURLWP=hypercall -V RUMP_LOCKS_UP=yes \
	-V MKPIC=no -V RUMP_KERNEL_IS_LIBC=1 \
	-F CFLAGS=-fno-stack-protector \
	-k -s ${RUMPSRC} -o ${RUMPOBJ} -d ${RUMP} \
	${BUILD_QUIET} ${STDJ} \
	-F CPPFLAGS="${EXTRA_CPPFLAGS}" \
	-F CFLAGS="${EXTRA_CFLAGS}" \
	-F AFLAGS="${EXTRA_AFLAGS}" \
	-F LDFLAGS="${EXTRA_LDFLAGS}" \
	-F CWARNFLAGS="${EXTRA_CWARNFLAGS}" \
	-F DBG="${F_DBG}" \
	${EXTRAFLAGS} \
	-l ${LKLSRC} tools linuxbuild install

}

rumpkernel_createuserlib()
{
# build musl libc for Linux
(
	set -x
	echo "=== building musl ==="
	cd musl
	LKL_HEADER="${RUMP}/lkl-linux/"
	CIRCLE_TEST_REPORTS="${CIRCLE_TEST_REPORTS-./}"
	./configure --with-lkl=${LKL_HEADER} --disable-shared --enable-debug \
		    --disable-optimize --prefix=${RUMPOBJ}/musl 2>&1 | tee $CIRCLE_TEST_REPORTS/log-conf.txt
	make install 2>&1 | tee $CIRCLE_TEST_REPORTS/log-make.txt
)
}

rumpkernel_install_header()
{
	## FIXME: MUSL_LIBC is somehow misleading as franken also uses.
	## LINUX_LIBC?
	appendvar FRANKEN_FLAGS "-DMUSL_LIBC"
	appendvar EXTRA_CPPFLAGS "-DCONFIG_LKL"
	appendvar EXTRA_CFLAGS "-DCONFIG_LKL"

	# install headers
	cp -a ${RUMP}/lkl-linux/usr/include/* ${OUTDIR}/include
	cp -a ${RUMPOBJ}/musl/include/* ${OUTDIR}/include

}

rumpkernel_install_extra_libs ()
{
	return
}

rumpkernel_explode_libc()
{
(
	cd ${RUMPOBJ}/explode/musl
	${AR-ar} x ${RUMPOBJ}/musl/lib/libc.a
)
	LIBC_DIR=musl

	# XXX: need more appropriate place to do this
	cp ${RUMPOBJ}/rumpkernel/netconfig.o ${RUMPOBJ}/explode/rumpkernel

}

rumpkernel_build_extra()
{
	RUMPSRC=${RUMPSRC} \
	RUMPOBJ=${RUMPOBJ} \
	OUTDIR=${OUTDIR} \
	BINDIR=${BINDIR} \
		${MAKE} ${STDJ} -C rumpkernel/linux
}

rumpkernel_maketools()
{
	return
}

rumpkernel_build_test()
{
	OBJDIR=${RUMPOBJ}/tests

	# XXX qemu-arm still has an issue on pthread_self() during setuid
	if [ ${OS} != "qemu-arm" ] ;
	then
		${MAKE} -C tests/iputils clean
		CC="${BINDIR}/${COMPILER}" ${MAKE} -C tests/iputils ping ping6
		cp tests/iputils/ping tests/iputils/ping6 ${OBJDIR}/
		${MAKE} -C tests/iputils clean
	fi
}
