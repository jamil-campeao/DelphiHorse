object DMGlobal: TDMGlobal
  OnCreate = DataModuleCreate
  Height = 262
  Width = 339
  object conn: TFDConnection
    Params.Strings = (
      'DriverID=FB'
      'User_Name=sysdba'
      'Password=masterkey')
    LoginPrompt = False
    BeforeConnect = connBeforeConnect
    Left = 136
    Top = 104
  end
  object FDPhysFBDriverLink1: TFDPhysFBDriverLink
    VendorLib = 'C:\FarolTI\fbclient.DLL'
    Left = 232
    Top = 80
  end
end