classdef dict
   % A class emulating python style dictionaries
   properties
      Data
      Description
   end
   properties (SetAccess = private)
      Date
   end
   methods
      function obj = MyDataClass(data,desc)
         % Support 0-2 args
         if nargin > 0
            obj.Data = data;
         end
         if nargin > 1
            obj.Description = desc;
         end
         obj.Date = clock;
      end
      
      function sref = subsref(obj,s)
         % obj(i) is equivalent to obj.Data(i)
         switch s(1).type
            case '.'
               sref = builtin('subsref',obj,s);
            case '()'
               if length(s)<2
                  sref = builtin('subsref',obj.Data,s);
               else
                  sref = builtin('subsref',obj,s);
               end
            case '{}'
               error('MyDataClass:subsref',...
                  'Not a supported subscripted reference')
         end
      end
      
      function obj = subsasgn(obj,s,val)
         if isempty(s) && isa(val,'MyDataClass')
            obj = MyDataClass(val.Data,val.Description);
         end
         switch s(1).type
            case '.'
               obj = builtin('subsasgn',obj,s,val);
            case '()'
               %
               if length(s)<2
                  if isa(val,'MyDataClass')
                     error('MyDataClass:subsasgn',...
                        'Object must be scalar')
                  elseif isa(val,'double')
                     snew = substruct('.','Data','()',s(1).subs(:));
                     obj = subsasgn(obj,snew,val);
                  end
               end
            case '{}'
               error('MyDataClass:subsasgn',...
                  'Not a supported subscripted assignment')
         end
      end
      
      function a = double(obj)
         a = obj.Data;
      end
      
      function c = plus(obj,b)
         c = double(obj) + double(b);
      end
      
      function ind = end(obj,k,n)
         szd = size(obj.Data);
         if k < n
            ind = szd(k);
         else
            ind = prod(szd(k:end));
         end
      end
   end
end