using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Net;
using System.Net.Cache;
using System.Management.Automation;

namespace toolbox
{
    [Cmdlet(VerbsDiagnostic.Test,"HttpUrl")]
    public class TestHttpUrl : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = false,
            ValueFromPipelineByPropertyName = false,
            Position =0,
            HelpMessage = "A URL that starts with HTTP or HTTPS to be verified.")]
        [Alias("Uri", "Http")]
        public string Url { get; set; }

        [Parameter(
            Mandatory = false,
            ValueFromPipeline = false,
            ValueFromPipelineByPropertyName = false,
            HelpMessage = "The maximun number of automatic redirections to take.")]
        public int MaximumRedirection { get; set; } 

        [Parameter(
            Mandatory = false,
            ValueFromPipeline = false,
            ValueFromPipelineByPropertyName = false,
            HelpMessage = "The maximum amount of time to wait for a response, in seconds.")]
        public int TimeoutSecs { get; set; }

        [Parameter(
            Mandatory = false,
            ValueFromPipeline = false,
            ValueFromPipelineByPropertyName = false,
            HelpMessage = "Send user networking credential instead of anonymous credentials.")]
        public SwitchParameter SendUserCredentials { get; set; }

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            string status = "N/A";
            string user = Guid.NewGuid().ToString();
            string pwd = Guid.NewGuid().ToString();
            NetworkCredential anonymous = new NetworkCredential(user, pwd);

            HttpWebRequest httpRequest = (HttpWebRequest)WebRequest.Create(Url);
            httpRequest.KeepAlive = false;
            httpRequest.CachePolicy = new RequestCachePolicy(RequestCacheLevel.BypassCache);
            httpRequest.Credentials = SendUserCredentials.IsPresent ? CredentialCache.DefaultNetworkCredentials : anonymous;
            if (MyInvocation.BoundParameters.ContainsKey("MaximumRedirection"))
            {
                httpRequest.AllowAutoRedirect = true;
                httpRequest.MaximumAutomaticRedirections = MaximumRedirection;
            }

            if (MyInvocation.BoundParameters.ContainsKey("TimeoutSecs"))
            {
                httpRequest.Timeout = TimeoutSecs * 1000;
            }

            try
            {
                using (WebResponse webResponse = httpRequest.GetResponse())
                {
                    status = webResponse is HttpWebResponse ? ((HttpWebResponse)webResponse).StatusCode.ToString() : webResponse.ToString();
                }

            }
            catch (WebException wex)
            {
                if (wex.Status == WebExceptionStatus.ProtocolError)
                {
                    status = (((HttpWebResponse)wex.Response).StatusCode).ToString();
                }
                else
                {
                    status = wex.Status.ToString();
                }
            }
            catch
            {
                throw;
            }

            httpRequest.Abort();
            WriteObject(status);
        }

        protected override void StopProcessing()
        {
            base.StopProcessing();
        }
    }
}
