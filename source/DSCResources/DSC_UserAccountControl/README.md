# Description

The resource allows you to configure the notification level of the User
Account Control for the computer.

The possible values of the parameter `NotificationLevel`:

- **AlwaysNotify**: You will be notified before programs make changes to your
  computer or to Windows settings that require the permissions of an administrator.
  When you're notified, your desktop will be dimmed, and you must either approve
  or deny the request in the UAC dialog box before you can do anything else on
  your computer. The dimming of your desktop is referred to as the secure desktop
  because other programs can't run while it's dimmed. This is the most secure
  setting. When you are notified, you should carefully read the contents of each
  dialog box before allowing changes to be made to your computer.
- **AlwaysNotifyAndAskForCredentials**: You will be notified before programs
  make changes to your computer or to Windows settings that require the permissions
  of an administrator. When you're notified, your desktop will be dimmed, and you
  must enter valid credentials to approve the request in the UAC dialog box.
  This notification level is the same as **AlwaysNotify** but you are always
  asked for valid credentials on the secure desktop.
- **NotifyChanges**: You will be notified before programs make changes to your
  computer that require the permissions of an administrator. You will not be notified
  if you try to make changes to Windows settings that require the permissions of
  an administrator. You will be notified if a program outside of Windows tries
  to make changes to a Windows setting. It's usually safe to allow changes to be
  made to Windows settings without you being notified. However, certain programs
  that come with Windows can have commands or data passed to them, and malicious
  software can take advantage of this by using these programs to install files
  or change settings on your computer. You should always be careful about which
  programs you allow to run on your computer.
- **NotifyChangesWithoutDimming**: You will be notified before programs make
  changes to your computer that require the permissions of an administrator.
  You will not be notified if you try to make changes to Windows settings that
  require the permissions of an administrator. You will be notified if a program
  outside of Windows tries to make changes to a Windows setting. This setting is
  the same as "NotifyChanges" but you are not notified on the secure desktop.
  Because the UAC dialog box isn't on the secure desktop with this setting, other
  programs might be able to interfere with the dialog's visual appearance. This
  is a small security risk if you already have a malicious program running on
  your computer.
- **NeverNotify**: You will not be notified before any changes are made to your
  computer. If you are logged on as an administrator, programs can make changes
  to your computer without you knowing about it. If you are logged on as a
  standard user, any changes that require the permissions of an administrator will
  automatically be denied. If you select this setting, you will need to restart
  the computer to complete the process of turning off UAC. Once UAC is off, people
  that log on as administrator will always have the permissions of an administrator.
  This is the least secure setting. When you set UAC to never notify, you open
  up your computer to potential security risks. If you set UAC to never notify,
  you should be careful about which programs you run, because they will have the
  same access to the computer as you do. This includes reading and making changes
  to protected system areas, your personal data, saved files, and anything else
  stored on the computer. Programs will also be able to communicate and transfer
  information to and from anything your computer connects with, including the
  Internet.
- **NeverNotifyAndDisableAll**: You will not be notified before any changes are
  made to your computer. If you are logged on as an administrator, programs can
  make changes to your computer without you knowing about it. If you are logged
  on as a standard user, any changes that require the permissions of an administrator
  will automatically be denied. If you select this setting, you will need to
  restart the computer to complete the process of turning off UAC. Once UAC is
  off, people that log on as administrator will always have the permissions of
  an administrator. This is the least secure setting same as "NeverNotify", but
  in addition EnableLUA registry key is disabled. EnableLUA controls the behavior
  of all UAC policy settings for the computer. If you change this policy setting,
  you must restart your computer. We do not recommend using this setting, but it
  can be selected for systems that use programs that are not certified for
  Windows 8, Windows Server 2012, Windows 7 or Windows Server 2008 R2 because
  they do not support UAC.

The possible values of the parameter `SecureDesktopEnabled`:

https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-gpsb/12867da0-2e4e-4a4f-9dc4-84a7f354c8d9
