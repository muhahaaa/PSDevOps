﻿function Update-ADOBuild
{
    <#
    .Synopsis
        Updates builds and build definitions
    .Description
        Updates builds and build definitions in Azure DevOps.
    .Link
        https://docs.microsoft.com/en-us/rest/api/azure/devops/build/builds/update%20build?view=azure-devops-rest-5.1
    .Link
        https://docs.microsoft.com/en-us/rest/api/azure/devops/build/definitions/update?view=azure-devops-rest-5.1
    #>
    [CmdletBinding(DefaultParameterSetName='build/builds/{buildId}',SupportsShouldProcess)]
    param(
    # The Organization
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [Alias('Org')]
    [string]
    $Organization,

    # The Project
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [string]
    $Project,

    # The server.  By default https://dev.azure.com/.
    [Parameter(ValueFromPipelineByPropertyName)]
    [uri]
    $Server = "https://dev.azure.com/",

    # The api version.  By default, 5.1.
    [string]
    $ApiVersion = "5.1",

    # The Build ID
    [Parameter(Mandatory,ParameterSetName='build/builds/{buildId}',ValueFromPipelineByPropertyName)]
    [string]
    $BuildID,

    # The updated build information.  This only needs to contain the changed information.
    [Parameter(Mandatory,ParameterSetName='build/builds/{buildId}',ValueFromPipelineByPropertyName)]
    [PSObject]
    $Build,

    # The Build Definition ID
    [Parameter(Mandatory,ParameterSetName='build/definitions/{definitionId}',ValueFromPipelineByPropertyName)]
    [string]
    $DefinitionID,

    # The new build definition.  This needs to contain the entire definition.
    [Parameter(Mandatory,ParameterSetName='build/definitions/{definitionId}',ValueFromPipeline)]
    [PSObject]
    $Definition,

    # A Personal Access Token
    [Alias('PAT')]
    [string]
    $PersonalAccessToken,

    # Specifies a user account that has permission to send the request. The default is the current user.
    # Type a user name, such as User01 or Domain01\User01, or enter a PSCredential object, such as one generated by the Get-Credential cmdlet.
    [pscredential]
    [Management.Automation.CredentialAttribute()]
    $Credential,

    # Indicates that the cmdlet uses the credentials of the current user to send the web request.
    [Alias('UseDefaultCredential')]
    [switch]
    $UseDefaultCredentials,

    # Specifies that the cmdlet uses a proxy server for the request, rather than connecting directly to the Internet resource. Enter the URI of a network proxy server.
    [uri]
    $Proxy,

    # Specifies a user account that has permission to use the proxy server that is specified by the Proxy parameter. The default is the current user.
    # Type a user name, such as "User01" or "Domain01\User01", or enter a PSCredential object, such as one generated by the Get-Credential cmdlet.
    # This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
    [pscredential]
    [Management.Automation.CredentialAttribute()]
    $ProxyCredential,

    # Indicates that the cmdlet uses the credentials of the current user to access the proxy server that is specified by the Proxy parameter.
    # This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
    [switch]
    $ProxyUseDefaultCredentials

    )

    begin {
        #region Copy Invoke-ADORestAPI parameters
        $invokeParams = . $getInvokeParameters $PSBoundParameters
        #endregion Copy Invoke-ADORestAPI parameters
    }


    process {


        $invokeParams.Uri = # First construct the URI.  It's made up of:
            "$(@(
                "$server".TrimEnd('/') # * The Server
                $Organization # * The Organization
                $Project # * The Project
                '_apis' #* '_apis'
                . $ReplaceRouteParameter $PSCmdlet.ParameterSetName #* and the replaced route parameters.
            )  -join '/')?$( # Followed by a query string, containing
            @(
                if ($ApiVersion) { # an api-version (if one exists)
                    "api-version=$ApiVersion"
                }
            ) -join '&'
            )"

        $subtypename = @($pscmdlet.ParameterSetName -replace '/{\w+}', '' -split '/')[-1].TrimEnd('s')
        $subtypeName =
            if ($subtypename -eq 'Build') {
                ''
            } else {
                '.' + $subtypename.Substring(0,1).ToUpper() + $subtypename.Substring(1)
            }
        $invokeParams.PSTypeName = @( # Prepare a list of typenames so we can customize formatting:
            "$Organization.$Project.Build$subTypeName" # * $Organization.$Project.Build
            "$Organization.Build$subTypeName" # * $Organization.Build
            "StartAutomating.PSDevOps.Build$subTypeName" # * PSDevOps.Build
        )


        if ($psCmdlet.ParameterSetName -eq 'build/builds/{buildId}') {
            $invokeParams.Method = 'PATCH'
            $invokeParams.Body = $Build
        } else {
            $invokeParams.Method = 'PUT'
            $invokeParams.Body = $Definition
        }


        if ($WhatIfPreference) {
            $invokeParams.Remove('PersonalAccessToken')
            return $invokeParams
        }


        if ($PSCmdlet.ShouldProcess("$($invokeParams.Method) $($invokeParams.Uri)")) {
            Invoke-ADORestAPI @invokeParams -Property @{
                Organization = $Organization
                Project = $Project
            }
        }
    }
}

