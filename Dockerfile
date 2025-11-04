FROM alpine:3.19
# workflow
# Install the packages we need. Avahi will be included
RUN echo -e "https://dl-cdn.alpinelinux.org/alpine/edge/testing\nhttps://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN apk add --no-cache cups
RUN apk add --no-cache cups-libs
RUN apk add --no-cache cups-pdf
RUN apk add --no-cache cups-client
RUN apk add --no-cache cups-filters
RUN apk add --no-cache cups-dev
RUN apk add --no-cache ghostscript
RUN apk add --no-cache hplip
RUN apk add --no-cache avahi
RUN apk add --no-cache inotify-tools
RUN apk add --no-cache python3
RUN apk add --no-cache python3-dev
RUN apk add --no-cache build-base
RUN apk add --no-cache wget
RUN apk add --no-cache rsync
# 修复：替换 py3-pycups 为 pycups（Alpine 标准包名）
# 指定具体版本安装
RUN apk add --no-cache pycups=2.0.1-r2
RUN apk add --no-cache perl
RUN rm -rf /var/cache/apk/*

#foo2zjs 1020 support
RUN apk add --no-cache git cmake vim && \
    git clone https://github.com/koenkooi/foo2zjs.git && \
    cd foo2zjs && \
    make && \
	wget -O sihp1020.dl http://oleg.wl500g.info/hplj/sihp1020.dl && \
    make install && \
	make cups && \
    cd .. && \
	rm -rf foo2zjs

RUN RUN apk add --no-cache \
    automake \
    gettext-dev \
    libtool \
    m4 \
    autoconf \
    mupdf-tools \
    jpeg-dev \
    libpng-dev \
    tiff-dev \
    libexif-dev \
    lcms2-dev \
    freetype-dev \
    qpdf \
    qpdf-dev \
    dbus \
    dbus-dev \
	&& rm -rf /var/cache/apk/*

# Build and install brlaser from source
#RUN apk add --no-cache git cmake && \  
#	# 补充 g++、make（编译必需）
#    git clone https://github.com/pdewacht/brlaser.git && \
#    cd brlaser && \
#    # 添加兼容参数，解决 CMake 版本过高问题
#    cmake . -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release && \
#    make && \
#    make install && \
#    cd .. && \
#    rm -rf brlaser

# Build and install gutenprint from source
#RUN wget -O gutenprint-5.3.5.tar.xz https://sourceforge.net/projects/gimp-print/files/gutenprint-5.3/5.3.5/gutenprint-5.3.5.tar.xz/download && \
#    tar -xJf gutenprint-5.3.5.tar.xz && \
#    cd gutenprint-5.3.5 && \
#    # Patch to rename conflicting PAGESIZE identifiers to GPT_PAGESIZE in all files in src/testpattern
#    find src/testpattern -type f -exec sed -i 's/\bPAGESIZE\b/GPT_PAGESIZE/g' {} + && \
#    ./configure && \
#    make -j$(nproc) && \
#    make install && \
#    cd .. && \
#    rm -rf gutenprint-5.3.5 gutenprint-5.3.5.tar.xz && \
#    # Fix cups-genppdupdate script shebang
#    sed -i '1s|.*|#!/usr/bin/perl|' /usr/sbin/cups-genppdupdate

# This will use port 631
EXPOSE 631

# We want a mount for these
VOLUME /config
VOLUME /services

# Add scripts
ADD root /
RUN chmod +x /root/*

#Run Script
CMD ["/root/run_cups.sh"]

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
 	sed -i 's/IdleExitTimeout/#IdleExitTimeout/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/.*enable\-dbus=.*/enable\-dbus\=no/' /etc/avahi/avahi-daemon.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf && \
	echo "ReadyPaperSizes A4,TA4,4X6FULL,T4X6FULL,2L,T2L,A6,A5,B5,L,TL,INDEX5,8x10,T8x10,4X7,T4X7,Postcard,TPostcard,ENV10,EnvDL,ENVC6,Letter,Legal" >> /etc/cups/cupsd.conf && \
	echo "DefaultPaperSize Letter" >> /etc/cups/cupsd.conf && \
	echo "pdftops-renderer ghostscript" >> /etc/cups/cupsd.conf
