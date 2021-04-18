# Culture = "en-US"
ConvertFrom-StringData -StringData @'
    NoRestorePointsFound    = No checkpoints have been created on the computer. (SR0001)
    CreateRestorePoint      = Creating restore point on the target computer. Description = ['{0}']. (SR0002)
    NumRestorePoints        = Found '{0}' restore points that match the parameters provided. (SR0003)
    CheckpointFailure       = An error occurred trying to create the restore point. (SR0004)
    DeleteRestorePoint      = Deleting restore point ('{0}'/'{1}'). (SR0005)
    DeleteCheckpointFailure = An error occurred trying to delete the restore point. (SR0006)
    RestorePointProperties  = Retrieved restore point with Ensure = ['{0}'] and restore point type = ['{1}']. (SR0007)
'@
