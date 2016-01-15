PHP_ARG_WITH(zmq,     whether to enable 0MQ support,
[  --with-zmq[=DIR]   Enable 0MQ support. DIR is the prefix to libzmq installation directory.], yes)

PHP_ARG_ENABLE(zmq_pthreads,    whether to enable support for php threads extension,
[  --enable-zmq-pthreads        whether to enable support for php threads extension], no, no)

PHP_ARG_WITH(czmq,    whether to enable CZMQ support,
[  --with-czmq[=DIR]  Enable CZMQ support. DIR is the prefix to CZMQ installation directory.], no, no)

if test "$PHP_ZMQ" != "no"; then

  AC_PATH_PROG(PKG_CONFIG, pkg-config, no)
  if test "x$PKG_CONFIG" = "xno"; then
    AC_MSG_RESULT([pkg-config not found])
    AC_MSG_ERROR([Please reinstall the pkg-config distribution])
  fi

  ORIG_PKG_CONFIG_PATH=$PKG_CONFIG_PATH

  PHP_ZMQ_EXPLICIT_PKG_CONFIG_PATH=""

  AC_MSG_CHECKING(libzmq installation)
  if test "x$PHP_ZMQ" = "xyes"; then
    if test "x${PKG_CONFIG_PATH}" = "x"; then
      #
      # "By default, pkg-config looks in the directory prefix/lib/pkgconfig for these files"
      #
      # Add a bit more search paths for common installation locations. Can be overridden by setting
      # PKG_CONFIG_PATH env variable or passing --with-zmq=PATH
      #
      export PKG_CONFIG_PATH="/usr/local/${PHP_LIBDIR}/pkgconfig:/usr/${PHP_LIBDIR}/pkgconfig:/opt/${PHP_LIBDIR}/pkgconfig:/opt/local/${PHP_LIBDIR}/pkgconfig"
    fi
  else
    export PKG_CONFIG_PATH="${PHP_ZMQ}/${PHP_LIBDIR}/pkgconfig"
    export PHP_ZMQ_EXPLICIT_PKG_CONFIG_PATH="${PKG_CONFIG_PATH}"
  fi

  if $PKG_CONFIG --exists libzmq; then
    PHP_ZMQ_VERSION=`$PKG_CONFIG libzmq --modversion`
    PHP_ZMQ_PREFIX=`$PKG_CONFIG libzmq --variable=prefix`

    AC_MSG_RESULT([found version $PHP_ZMQ_VERSION, under $PHP_ZMQ_PREFIX])
    PHP_ZMQ_LIBS=`$PKG_CONFIG libzmq --libs`
    PHP_ZMQ_INCS=`$PKG_CONFIG libzmq --cflags`

    PHP_EVAL_LIBLINE($PHP_ZMQ_LIBS, ZMQ_SHARED_LIBADD)
    PHP_EVAL_INCLINE($PHP_ZMQ_INCS)
  else
    AC_MSG_ERROR(Unable to find libzmq installation)
  fi

  if test "$PHP_CZMQ" != "no"; then
    if test "x$PHP_CZMQ" != "xyes"; then
      export PKG_CONFIG_PATH="${PHP_CZMQ}/${PHP_LIBDIR}/pkgconfig:${PHP_ZMQ_EXPLICIT_PKG_CONFIG_PATH}"
    fi

    AC_MSG_CHECKING(for czmq)
    if $PKG_CONFIG --exists libczmq; then

      AC_MSG_RESULT([yes])

      AC_MSG_CHECKING([czmq version is below 3.0.0])
      if $PKG_CONFIG libczmq --max-version=3.0.0; then
        AC_MSG_RESULT([ok])
      else
        AC_MSG_ERROR([Only czmq 2.x is supported at the moment])
      fi
    
      PHP_CZMQ_VERSION=`$PKG_CONFIG libczmq --modversion`
      PHP_CZMQ_PREFIX=`$PKG_CONFIG libczmq --variable=prefix`
      AC_MSG_RESULT([found version $PHP_CZMQ_VERSION in $PHP_CZMQ_PREFIX])

      PHP_CZMQ_LIBS=`$PKG_CONFIG libczmq --libs`
      PHP_CZMQ_INCS=`$PKG_CONFIG libczmq --cflags`

      PHP_EVAL_LIBLINE($PHP_CZMQ_LIBS, ZMQ_SHARED_LIBADD)
      PHP_EVAL_INCLINE($PHP_CZMQ_INCS)

      AC_DEFINE([HAVE_CZMQ], [], [czmq was found])
      AC_DEFINE([HAVE_CZMQ_2], [], [czmq was found])
    else
      AC_MSG_RESULT([no])
    fi
  fi

  AC_CHECK_HEADERS([stdint.h],[php_zmq_have_stdint=yes; break;])
  if test $php_zmq_have_stdint != "yes"; then
    AC_MSG_ERROR(Unable to find stdint.h)
  fi

  if test "x$PHP_ZMQ_PTHREADS" = "xyes"; then
    AC_MSG_CHECKING([for ZTS])

    if test "$PHP_THREAD_SAFETY" != "no"; then
      AC_MSG_RESULT([ok])
    else
      AC_MSG_ERROR([pthreads requires ZTS, please re-compile PHP with ZTS enabled])
    fi
    AC_DEFINE(PHP_ZMQ_PTHREADS, 1, [Enable support for phtreads])
  fi

  AC_CHECK_HEADERS(time.h sys/time.h mach/mach_time.h)
  AC_SEARCH_LIBS(clock_gettime, rt)
  AC_CHECK_FUNCS(clock_gettime gettimeofday mach_absolute_time)

  PHP_SUBST(ZMQ_SHARED_LIBADD)
  
  PHP_ZMQ_VERNUM=`${PHP_CONFIG} --vernum`

  if test "$PHP_ZMQ_VERNUM" -lt "70000"; then
    subdir="php5"

    PHP_ADD_BUILD_DIR($abs_builddir/$subdir, 1)
    PHP_NEW_EXTENSION(zmq, $subdir/zmq.c $subdir/zmq_pollset.c $subdir/zmq_device.c $subdir/zmq_sockopt.c $subdir/zmq_fd_stream.c $subdir/zmq_clock.c, $ext_shared)
  else
    PHP_NEW_EXTENSION(zmq, zmq.c zmq_pollset.c zmq_device.c zmq_sockopt.c zmq_fd_stream.c zmq_clock.c zmq_czmq.c, $ext_shared)
  fi
  PKG_CONFIG_PATH="$ORIG_PKG_CONFIG_PATH"
fi
