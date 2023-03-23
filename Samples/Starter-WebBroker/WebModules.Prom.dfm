object PromWebModule: TPromWebModule
  Actions = <
    item
      Default = True
      Enabled = False
      Name = 'DefaultHandler'
      PathInfo = '/'
      OnAction = PromWebModuleDefaultHandlerAction
    end
    item
      MethodType = mtGet
      Name = 'MetricAction'
      PathInfo = '/metrics'
      OnAction = PromWebModuleMetricActionAction
    end
    item
      MethodType = mtGet
      Name = 'Leak'
      PathInfo = '/leak'
      OnAction = PromWebModuleLeakAction
    end>
  BeforeDispatch = WebModuleBeforeDispatch
  AfterDispatch = WebModuleAfterDispatch
  Height = 312
  Width = 401
end
