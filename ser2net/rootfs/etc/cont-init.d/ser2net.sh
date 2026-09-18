#!/usr/bin/with-contenv bashio

data_port=12345
admin_port=12346

device_path=$(bashio::config serial_device)
network_mode=$(bashio::config network_mode)
baudrate=$(bashio::config baudrate)
data_bits=$(bashio::config data_bits)
parity=$(bashio::config parity)
stop_bits=$(bashio::config stop_bits)
flow_control=$(bashio::config flow_control)
max_connections=$(bashio::config max_connections 1)

# Build serial parameters
case "$parity" in
  none)
    parity_code="N"
    ;;
  even)
    parity_code="E"
    ;;
  odd)
    parity_code="O"
    ;;
  *)
    bashio::exit.nok "Invalid parity: $parity"
    ;;
esac

serial_params="${baudrate}${parity_code}${data_bits}${stop_bits}"

# Add flow control if requested
case "$flow_control" in
  none)
    flow_option=""
    ;;
  rtscts)
    flow_option=",RTSCTS"
    ;;
  xonxoff)
    flow_option=",XONXOFF"
    ;;
  *)
    bashio::exit.nok "Invalid flow control: $flow_control"
    ;;
esac

# local ignores modem control lines, which is normally what is wanted
serial_params="${serial_params}${flow_option},local"

# nobreak prevents a break being generated when the serial port is opened
if bashio::config.true "no_break"; then
  serial_params="${serial_params},nobreak"
fi

# Build network accepter
case "$network_mode" in
  tcp)
    accepter="tcp,${data_port}"
    ;;
  rfc2217)
    accepter="telnet(rfc2217),tcp,${data_port}"
    ;;
  *)
    bashio::exit.nok "Invalid network mode: $network_mode"
    ;;
esac

cat >> /etc/ser2net/ser2net.yaml << EOF

connection: &serport
  accepter: ${accepter}
  timeout: 0
  enable: on
  connector: serialdev,${device_path},${serial_params}
  options:
    max-connections: ${max_connections}

EOF

if bashio::config.true "enable_admin_interface"; then
cat >> /etc/ser2net/ser2net.yaml << EOF

admin:
  accepter: tcp,${admin_port}

EOF
fi
