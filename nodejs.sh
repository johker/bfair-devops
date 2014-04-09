#
# THIS FILE IS MANAGED VIA PUPPET - DON'T CHANGE ANY CONTENT HERE!
#
NODEJS_HOME=/usr/local/node/node-default

if [ -d "$NODEJS_HOME/bin" ] ; then
  export PATH="$NODEJS_HOME/bin:$PATH"
fi

