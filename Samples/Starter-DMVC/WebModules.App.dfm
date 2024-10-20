object AppWebModule: TAppWebModule
  OnCreate = WebModuleCreate
  OnDestroy = WebModuleDestroy
  Actions = <
    item
      Default = True
      Name = 'DefaultHandler'
      PathInfo = '/'
    end>
  Height = 288
  Width = 519
  PixelsPerInch = 120
end
