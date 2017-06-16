// Copyright 2016 Sysdata Digital
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

public func SDLogError(_ message: @autoclosure () -> String, file: StaticString = #file , function: StaticString = #function, line: UInt = #line)
{
    SDLogger.shared().log(with: .error, module: nil,  file: String(describing: file), function: String(describing: function), line: line, message: message())
}
public func SDLogInfo(_ message: @autoclosure () -> String, file: StaticString = #file , function: StaticString = #function, line: UInt = #line)
{
    SDLogger.shared().log(with: .info, module: nil,  file: String(describing: file), function: String(describing: function), line: line, message: message())
}
public func SDLogWarning(_ message: @autoclosure () -> String, file: StaticString = #file , function: StaticString = #function, line: UInt = #line)
{
    SDLogger.shared().log(with: .warning, module: nil,  file: String(describing: file), function: String(describing: function), line: line, message: message())
}
public func SDLogVerbose(_ message: @autoclosure () -> String, file: StaticString = #file , function: StaticString = #function, line: UInt = #line)
{
    SDLogger.shared().log(with: .verbose, module: nil,  file: String(describing: file), function: String(describing: function), line: line, message: message())
}
