<?php
// THIS IS AUTOGENERATED BY builtins_php.ml
class CacheClientCore {
const INTERNAL_ROUTER = 0;
const EXTERNAL_ROUTER = 0;
 function getFeatures() { }
 function setLogFile($file) { }
 function setLogLevel($level) { }
 function __construct($params) { }
 function __destruct() { }
 function send(&$msgs) { }
 function loopOnce($timeout) { }
 function flushSends() { }
 function getCompleted() { }
 function setTimeout($seconds, $microseconds) { }
 function setKeepalive($keepcnt, $keepidle, $keepintvl) { }
 function setTcpRtoMin($tcpRtoMin) { }
 function getConfigOptions() { }
 function router_stats_age($name) { }
 function router_stats($name, $clear = 0) { }
 function reset() { }
 function stats($clear = 0) { }
 function checkPrerequisites($param, &$err) { }
const mc_client_ok = 0;
const mc_client_invalid_handle = 0;
const mc_client_invalid_state = 0;
const mc_client_out_of_memory = 0;
const mc_client_unsupported_transport = 0;
const mc_client_unsupported_protocol = 0;
const mc_client_transport_error = 0;
const mc_client_unknown_error = 0;
const mc_client_err_request_not_found = 0;
const mc_client_err_unexpected_result = 0;
const mc_client_err_protocol_error = 0;
const mc_client_use_transparent_decompression = 0;
const mc_client_allow_out_of_order = 0;
const mc_client_opt_timeout = 0;
const mc_client_opt_tcp_rto_min = 0;
const mc_client_opt_keepalive = 0;
const mc_client_opt_set = 0;
const mc_client_opt_field_invalid = 0;
const mc_client_opt_value_invalid = 0;
const mc_client_opt_unimplemented = 0;
const mc_client_nzlib_compress = 0;
const mc_op_unknown = 0;
const mc_op_echo = 0;
const mc_op_quit = 0;
const mc_op_version = 0;
const mc_op_servererr = 0;
const mc_op_get = 0;
const mc_op_set = 0;
const mc_op_add = 0;
const mc_op_replace = 0;
const mc_op_append = 0;
const mc_op_prepend = 0;
const mc_op_cas = 0;
const mc_op_delete = 0;
const mc_op_ldelete = 0;
const mc_op_incr = 0;
const mc_op_decr = 0;
const mc_op_flushall = 0;
const mc_op_flushre = 0;
const mc_op_stats = 0;
const mc_op_verbosity = 0;
const mc_op_lease_get = 0;
const mc_op_lease_set = 0;
const mc_op_shutdown = 0;
const mc_op_end = 0;
const mc_op_metaget = 0;
const mc_nops = 0;
const mc_res_unknown = 0;
const mc_res_deleted = 0;
const mc_res_found = 0;
const mc_res_notfound = 0;
const mc_res_notstored = 0;
const mc_res_stalestored = 0;
const mc_res_ok = 0;
const mc_res_stored = 0;
const mc_res_exists = 0;
const mc_res_ooo = 0;
const mc_res_timeout = 0;
const mc_res_connect_timeout = 0;
const mc_res_bad_command = 0;
const mc_res_bad_key = 0;
const mc_res_bad_flags = 0;
const mc_res_bad_exptime = 0;
const mc_res_bad_lease_id = 0;
const mc_res_bad_value = 0;
const mc_res_aborted = 0;
const mc_res_client_error = 0;
const mc_res_local_error = 0;
const mc_res_remote_error = 0;
const mc_res_waiting = 0;
const mc_nres = 0;
const mc_msg_flag_nzlib_compressed = 0;
}
