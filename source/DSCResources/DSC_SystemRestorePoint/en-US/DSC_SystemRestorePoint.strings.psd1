# Culture = "en-US"
ConvertFrom-StringData -StringData @'
    NotWorkstationOS        = This resource can only be used on workstation operating systems. (SR0001)
    ReturningTrueToBeSafe   = The test will evaluate to True to prevent an unintentional set targeting a server operating system. (SP0002)
    NoRestorePointsFound    = No checkpoints have been created on the computer. (SR0003)
    CreateRestorePoint      = Creating restore point on the target computer. Description = [{0}]. (SR0004)
    NumRestorePoints        = Found {0} restore points that match the parameters provided. (SR0005)
    CheckpointFailure       = An error occurred trying to create the restore point. (SR0006)
    DeleteRestorePoint      = Deleting restore point ({0}/{1}). (SR0007)
    DeleteCheckpointFailure = An error occurred trying to delete the restore point. (SR0008)
    RestorePointProperties  = Retrieved restore point with Ensure = [{0}] and restore point type = [{1}]. (SR0009)
'@
