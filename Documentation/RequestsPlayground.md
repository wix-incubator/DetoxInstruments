# Requests Playground

Detox Instruments includes a utility for replaying and modifying network requests, called Requests Playground. These requests can be saved as a document for future reference and testing.

Create a new request document by either selecting **File** ➔ **New** ➔ **Request**, or by selecting a network request from a profiling recording and clicking the **Open in Requests Playground** button in the inspector pane.

![Requests Playground](Resources/RequestsPlayground.png)

The document window includes three sections: the top section, gives control over the URL and the HTTP method of the request; the middle section gives control over the request’s content; and the bottom section has actions to perform for the request.

### Request URL And HTTP Method

In this section, you set the HTTP method and the URL of the request. Modifying the URL will automatically regenerate the content in the **Query String** section.

### Request & Response Content

This section gives you control of the request content as well as the output from the response.

#### Headers

You modify the headers of the request in this section. Modifying the `Cookie` header will automatically regenerate the **Cookies** section. Modifying the `Content-Type` header will automatically modify the content type in the **Body** section.

#### Cookies

You modify the cookies of the request in this section. Modifying items in this list will override the `Cookie` header in the **Headers** section.

#### Query String

You modify the query string arguments of the request in this section. Modifying items in this list will cause the URL of the request to be regenerated.

#### Body

You modify the body of the request in this section. At the bottom of the section, you can select the body types supported by Requests Playground, as well as the content type.

Supported body types:

- None
- Raw Text
- URL Encoded Form
- File

Selecting the **URL Encoded Form** body type will attempt to interpret the body content as URL encoded key/value pairs. Selecting or dragging a file when in **File** body type will attempt to set the body content type from the file type of the file.

The **Content Type** text field allows you to manually set the body content type in MIME format. Setting this field or making changes to the body type will cause the `Content-Type` header to be regenerated.

#### Response

You view the response metrics and response headers and content in this section. If there was an error when executing the request, it will be displayed in this section. You can open the response content or save it as a file.

### Request Actions

Once you finish modifying your request, you can execute it by clicking the **Send Request** button. When the request execution finishes, the **Response** section will be enabled.

You can also copy a code snippet for executing the request in your environment. The supported snippet environments are:

- cURL
- Node

> Copying a snippet with a long body is not recommended as the body content will be copied as base 64.