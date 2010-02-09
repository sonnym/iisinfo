<%@ Page Language="C#" ClassName="IISInfo" EnableSessionState="false" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Web" %>
<script runat="server">
	// Settings
	private string refresh = "300";
	private string[] monitor = { "w3wp.exe", "aspnet_state.exe", "sqlservr.exe" };
	//////////

	private string hostname = runProcess("hostname");

	private static string commandString = "cmd.exe";
	private static string commandAttributes = " /q /c ";
	private string tmpfiles = "dir /B %tmp%";
	private string netstat = "netstat -n";
	private string ps = "tasklist";
	private string uptime = "net stats srv";

	private DateTime now = DateTime.Now;

	private string psResult = String.Empty;
	private string uptimeResult = String.Empty;

	private string monitorDisp = String.Empty;
	private string driveDisp = String.Empty;
	private string uptimeDisp = String.Empty;
	private string memAvailDisp = String.Empty;
	private string pageUseDisp = String.Empty;
	private string iisThreadDisp = String.Empty;
	private string sqlThreadDisp = String.Empty;

	private void Page_Load(object sender, EventArgs e) {
		Regex rgx;

		psResult = runProcess(ps);
		foreach (string p in monitor) {
			rgx = new Regex(Regex.Escape(p) + @"\b", RegexOptions.IgnoreCase);
			monitorDisp += "<span class=\"" + ((rgx.IsMatch(psResult)) ? "up" : "down") + "\">" + p + "</span>";
		}

		DriveInfo[] drives = DriveInfo.GetDrives();
		foreach (DriveInfo d in drives) {
			try {
				driveDisp += "<span>" + d.Name + " (" + Convert.ToString(Math.Floor((float)(d.TotalSize - d.AvailableFreeSpace) / d.TotalSize * 100))  + "%)</span>";
			} catch {}
		}

		// Environment.TickCount is a substitute to this command
		uptimeResult = runProcess(uptime);
		rgx = new Regex("^Statistics since .+$", RegexOptions.Multiline);
		uptimeDisp = now.Subtract(DateTime.Parse(rgx.Match(uptimeResult).ToString().Trim().Substring(16))).ToString();

		PerformanceCounter pc = new PerformanceCounter("Memory", "Available Bytes");
		try {
			memAvailDisp = bytesToHumanReadible(pc.NextValue().ToString());
		} catch {
			memAvailDisp = "err";
		}

		pc = new PerformanceCounter("Paging File", "% Usage", "_Total", ".");
		try {
			pageUseDisp = Math.Round(float.Parse(pc.NextValue().ToString()), 1).ToString() + "%"; 
		} catch {
			pageUseDisp = "err";
		}

		pc = new PerformanceCounter("Process", "Thread Count", "w3wp", ".");
		try {
			iisThreadDisp = pc.NextValue().ToString();
		} catch {
			iisThreadDisp = "err";
		}

		pc = new PerformanceCounter("Process", "Thread Count", "sqlservr", ".");
		try { // System.InvalidOperationException: Instance 'sqlservr' does not exist in the specified Category.
			sqlThreadDisp = pc.NextValue().ToString();
		} catch {
			sqlThreadDisp = "err";
		}
	}

	private static string runProcess(string command) {
		Process process = new Process();
		process.StartInfo.FileName = commandString;
		process.StartInfo.Arguments = commandAttributes + command;
		process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
		process.StartInfo.CreateNoWindow = true;
		process.StartInfo.UseShellExecute = false;
		process.StartInfo.RedirectStandardOutput = true;
		process.StartInfo.RedirectStandardError = true;

		process.Start();
		process.WaitForExit();

		if (process.ExitCode == 0) return process.StandardOutput.ReadToEnd().Trim();
		else return String.Empty;
	}

	private string bytesToHumanReadible(string s) {
		string denom = "B";
		float f = float.Parse(s);
		while (f > 1023) {
			f /= 1024;
			switch(denom) {
				case "B": denom = "KB"; break;
				case "KB": denom = "MB"; break;
				case "MB": denom = "GB"; break;
				case "GB": denom = "TB"; break;
			}
		}
		return Math.Round(f, 1).ToString() + " " + denom;
	}
</script>
<html>
 <head>
  <meta http-equiv="refresh" content="<%=refresh%>" />
  <style type="text/css">
    body { background: #000000; color: #eeeeee; margin: 0px; padding: 2px; font-size: 0.85em; }
    table { width: 100%; font-size: 11px; }
    table td { padding: 0px; vertical-align: top; }
    table.summary { border: solid 1px #999999; table-layout: fixed; border-collapse: collapse; cell-spacing: 0px; }
    table.raw { border-collapse: separate; border-spacing: 3px; }
    table.raw td { border: solid 1px #999999; }
    div { padding: 2px; }
    div.title { height: 13px; background: #333333; border-bottom: solid 1px #999999; font-weight: 600; }
    div.pre { margin: 0px; height: 350px; overflow: auto; }
    span { margin: 0px 2px; font-weight: normal; }
    span.down { color: #ff0000; }
    h1, h2, h4 { margin: 0px; }
    pre { color: 00ff00; margin: 0px; padding: 2px; }
    .right { text-align: right; }
  </style>
  <title>
   <%=hostname %> : IIS Information
  </title>
 </head>
 <body>
  <table class="summary">
   <tbody>
    <tr>
     <td colspan="2">
      <div class="title">
       <%=monitorDisp%>
      </div>
     </td>
     <td colspan="2" class="right">
      <div class="title">
       <span>Disk Usage:</span>
       <%=driveDisp%>
      </div>
     </td>
    </tr>
    <tr>
     <td>
      <div>
       <h1><%=hostname%></h1>
        <h4><%=now.ToString()%> (up <%=uptimeDisp%>)</h4>
      </div>
     </td>
     <td>&nbsp;</td>
     <td>
      <table>
       <tbody>
        <tr>
         <td>
          Free RAM
          <br />
          <h2><%=memAvailDisp%></h2>
         </td>
         <td>
          Page File Use
          <br />
          <h2><%=pageUseDisp%></h2>
         </td>
         <td>
          IIS Threads
          <br />
          <h2><%=iisThreadDisp%></h2>
         </td>
         <td>
          SQL Threads
          <br />
          <h2><%=sqlThreadDisp%></h2>
         </td>
        </tr>
       </tbody>
      </table>
     </td>
     <td>&nbsp;</td>
    </tr>
   </tbody>
  </table>
  <table class="raw">
   <tbody>
    <tr>
     <td>
      <div class="title"><%=commandString + commandAttributes + ps%></div>
      <div class="pre">
       <pre><%=runProcess(ps)%></pre>
      </div>
     </td>
     <td rowspan="2">
      <div class="title"><%=commandString + commandAttributes + tmpfiles%></div>
      <div class="pre" style="height: 727px">
       <pre><%=runProcess(tmpfiles)%></pre>
      </div>
     </td>
    </tr>
    <tr>
     <td>
      <div class="title"><%=commandString + commandAttributes + netstat%></div>
      <div class="pre">
       <pre><%=runProcess(netstat)%></pre>
      </div>
     </td>
    </tr>
   </tbody>
  </table>
 </body>
</html>
