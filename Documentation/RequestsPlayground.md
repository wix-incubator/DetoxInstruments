# Requests Playground

Detox Instruments includes a utility for replaying and modifying network requests, called Requests Playground.

Start by selecting a network request from an existing recording. In the inspector pane, scroll down to the **Request** section and click on the **Open in Requests Playground** button. The Requests Playground window will open with the details of the request.

![Requests Playground](Resources/RequestsPlayground.png)

At the top section, you can select the HTTP request method and modify the request URL.

At the middle section, you can modify the parameters of your request.

- **Headers**—Modify the headers of the request

- **Cookies**—Modify the cookies of the request; modifying this list will override the `Cookie` header

- **Query String**—Modify the query string arguments of the request; modifying this list will modify the address of the request

- **Body**—Modify the body of the request

  - > Note: Currently, only text body content is supported.

- **Response Headers**—View the response headers after sending a request
- **Response Body**—View the response content or the error received when executing the request

Once you finish modifying your request, you can execute it by clicking the **Send Request** button or you can copy a code snippet for executing the request in your environment.

> Note: Currently, cURL and Node are supported snippet languages.