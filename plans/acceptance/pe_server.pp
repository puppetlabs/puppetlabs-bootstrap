# @summary Install PE Server
#
# Install PE Server
#
# @example
#   bootstrap::acceptance::pe_server
plan bootstrap::acceptance::pe_server(
  Optional[String] $version = '2021.7.8',
  Optional[Hash] $pe_settings = { password => 'puppetlabs' }
) {
  #identify pe server node
  $puppet_server =  get_targets('*').filter |$n| { $n.vars['role'] == 'ntpserver' }

  # install pe server
  run_plan(
    'deploy_pe::provision_master',
    'localhost',
    'version' => $version,
    'pe_settings' => $pe_settings
  )
}
