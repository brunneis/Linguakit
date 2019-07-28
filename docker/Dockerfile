FROM ubuntu:18.04

RUN \
	apt-get update \
	&& dpkg-query -Wf '${Package}\n' | sort > /tmp/init_pkgs \
	&& apt-get -y install git build-essential zlib1g-dev \
	&& dpkg-query -Wf '${Package}\n' | sort > /tmp/new_pkgs \
	&& cd /opt && git clone https://github.com/citiususc/Linguakit.git \
	&& cpan PerlIO::gzip \
	&& cpan LWP::UserAgent \
	&& apt-get -y purge $(diff -u /tmp/init_pkgs /tmp/new_pkgs | grep -E "^\+" | cut -d + -f2- | sed -n '1!p' | grep -v perl) \
	&& apt-get -y install $(diff -u /tmp/init_pkgs /tmp/new_pkgs | grep -E "^\+" | cut -d + -f2- | sed -n '1!p' | grep perl)

ENV PATH=$PATH:/opt/Linguakit
ENTRYPOINT ["linguakit"]