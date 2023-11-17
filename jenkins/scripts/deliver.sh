set -x
npm start -- --port 3000 --host 0.0.0.0 &
sleep 15
echo $! > .pidfile
set +x