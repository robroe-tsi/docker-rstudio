FROM bigboards/cdh-base-x86_64

MAINTAINER robroetsi
USER root

# install dependencies
RUN apt-get update && \
	apt-get install -y gdebi-core libapparmor1 wget libcurl4-openssl-dev 

# install latest R Base 
RUN codename=$(lsb_release -c -s) && \
	echo "deb http://freestatistics.org/cran/bin/linux/ubuntu $codename/" | tee -a /etc/apt/sources.list > /dev/null && \
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9 && \
	apt-get update && apt-get install -y r-base r-base-dev

# install R libraries
RUN R -e 'install.packages(c("ggplot2","caret","tidyr","stringr","caretEnsemble","party","devtools","randomForest","ada","doMC","evaluate","formatR","highr","markdown","yaml","htmltools","caTools","bitops","knitr","rmarkdown","ROCR","gplots","dplyr","plyr","pROC","e1071","gbm"), repos="http://cran.freestatistics.org/", dependencies=NA,clean=TRUE)'  && \
	R -e 'library("devtools"); install_github("mbojan/alluvial")' && \
	R -e 'update.packages(ask=FALSE,repos="http://cran.freestatistics.org/")'
		
# install RStudio
RUN VER=$(wget --no-check-certificate -qO- https://s3.amazonaws.com/rstudio-server/current.ver) \
	&& wget -O /tmp/rstudio.deb http://download2.rstudio.org/rstudio-server-${VER}-amd64.deb \
	&& gdebi -n /tmp/rstudio.deb \
	&& rm /tmp/rstudio.deb
    
## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen en_US.utf8 && \
	/usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# Add users for RStudio, the sleep is added because older versions of docker have an issue with chmod
# ADD build_logins.sh /tmp/build_logins.sh
# RUN chmod +x /tmp/build_logins.sh && \
# 	sleep 1 && \
#  	./tmp/build_logins.sh 4 && \
# 	rm /tmp/build_logins.sh
RUN adduser --disabled-password --gecos "" bb \
	&& echo "bb:bigboards"|chpasswd

# Remove the package list to reduce image size. Note: do this as the last thing of the build process as installs can fail due to this!
# Additional cleanup
RUN apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#Add shell script with startup commands
ADD docker_files/rstudio-server-run.sh /apps/rstudio-server-run.sh
RUN chmod a+x /apps/*.sh

# Expose the RStudio Server port
EXPOSE 8787

# Start RStudio Server 
CMD ["/bin/bash"]