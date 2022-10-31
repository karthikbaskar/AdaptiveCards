<!-- AUTO-GENERATED: This section is auto-generated from schemas/adaptive-card.json. Do NOT add anything above this or edit anything inside, it MUST be the first thing in the document and will be overwritten. -->

# Dynamic Typeahead search
##Shared Object Model 

ChoiceSet will now have "choices.data property added to them. This property allow a card author to specify whether or not an input can dynamically fetch the list of choices from a remote backend/bot as the user types.
Additionally, a isMultiSelect:true will also be added to Input.ChoiceSet to allow users to select multiple choices from the list of choices, if set to true.

Choices.data property
| Property | Type | Required | Description | Version | Behaviour |
| -------- | ---- | -------- | ----------- | ------- | ------- |
| **type** | `Data.Query` | Yes | Specifies that this is a Data.Query object.  | 1.5 | If not specified or not set to Data.Query we will drop choices.data and the behaviour of Input.choiceset remains the same.
| **dataset** | `string` | Yes | The type of data that should be fetched dynamically | 1.5 | If not specified or invalid, we will drop choices.data and the behaviour of Input.choiceset remains the same.
| **value** | `string` | No | Populated for the invoke request to the bot with the input the user provided to the ChoiceSet  | 1.5 | optional
**skip** | `int` | No | Populated for the invoke request to the bot to specify how many elements should be returned (can be ignored by the bot, if they want to send a diff amount)  | 1.5 | optional
**count** | `int` | No | Populated for the invoke request to the bot to indicate that we want to paginate and skip ahead in the list  | 1.5 | optional

The below changes will define that a ChoiceSet needs to dynamically fetch data from the bot or from the client(in case of people picker).

## choices.data

`Choice.data` options.

### type
* **Type**: `type`
* **Required**: Yes
* **Allowed values**:
  * `Data.Query`


### dataset

* **Type**: `dataset`
* **Required**: Yes
* **Allowed values**:
  * only string is allowed

**Example card:**
Input.ChoiceSet
```json
{
    "type": "Input.ChoiceSet",
    "id": "selectedUser",
    "choices": [
        { "title": "Static 1", "value": "Static 1" }
    ],
    "choices.data": {
        "type": "Data.Query",
        "dataset": "graph.microsoft.com/users"
    },
     “isMultiSelect”: true
}
```

![img](assets/typeaheadshared.PNG)

Choices.data class in shared object model parses and serializes the choices.data property. Also, we will validate type as data.query which is defined in choices.data. We will have to identify what to do when there is an error in parsing. for eg: if any of the required properties are missing, we can either skip the deserialization/serialization for choices.data or return json parsing error to the host and host can show error view to the user. (This is the case where adaptive card rendering failed).

1. We can simply drop choices.data and will fallback to the existing experience of input.choiceset. We will make changes to the parsing logic for choices.data and the changes will allow cards to render even if the required properties are missed.
   Pros: This will not break rendering experience for the user.
2. Adaptive card rendering fails if required properties are not defined correctly. This behavior is due to the fact that the card has required properties are missing.
	Pros: Invalid json error returned to the host so developers can identify that there is some parsing related issue with the json.

Existing experience - If we fail to specify correct title and value props with choices prop then, adaptive card rendering fails.

OPEN QUESTIONS:
1. What should be the desired behaviour if required properties are missing? 

2. What should be the desired behaviour if there is an error in parsing choices.data. Scenario - If type is not defined as data.query or dataset is not string.

iOS Design

###Behaviour for static typeahead (filtered style)
On input change in the input.choiceset input control then dropdown menu only opens when user clicks on the chevron icon whereas on other clients it opens automatically whenever we have filtered results.

TODO: To check with SDK team - Is this the expected behaviour?
Here is the quick gif:


###Communication from host to sdk and sdk to hostt

Option 1:
To have async calls we can make use of notifications in iOS.

Option 2:
We will do communication asynchronously using compleion block.

### Communication with Host to fetch Dynamic choices

For this feature, we need two way communication with the host (host to sdk and sdk to host)
Why do we need?
 We will have to send the query to the host whenever query is changing in the input control so that host can make an invoke to the bot and once the choices is returned by the host we will update the choices in the UI.
 1. SDK to host: Sdk will notify the host about the query change in choiceset input control and then host can do the network/service call and return response to the sdk.
 2. Async Host to SDK : Now once host receives the choices from the bot and then will need to update the UX based on the dynamic choices received from the host. We will have completion block on the SDK side to handle this scenario.

### Option 1 (Recommended)

1. SDK will define the protocol **ACRInputDelegate** to communicate with the host. Host will need to implement the same protocol ACRInputDelegate as provided by the SDK. ACRMediaDelegate and ACRActionDelegate also uses the protocol method for one way communication.
2. Host will call the method into the render method of the AdaptiveCardRenderer and pass the cardActionHandler instance.
3. AdaptiveCardRenderer creates an instance of cardActionHandler and input handler. Also, views of all the components are added to this instance.
4. Now to render choicesetinput control, adaptiveCardRenderer will call ACRInputChoiceSetRenderer and pass the input choiceset delegate also. This will then call ACRChoiceSetCompactStyleView for compact,filtered and dynamic typeahead control rendering.
6. On any input change in choiceset control, SDK will notify the host with the help of delegate method asynchronously and will also paas the  query string and base action element that has choiceset properties.
7. Now host will make invoke call to the bot/service to fetch response for the sent query. Once host received a response with dynamic choices then host will simply return those choices to the SDK.
8. SDK will update the UI controls once response is received and will also update host to change any layout related constraint.

onChoiceSetQueryChange method paramters in ACRInputDelegate protocol
| Parameter | Type | Description |
| :------- | :----- | :------------------------------------------------------------------------------------------
| baseCardElement | BaseCardElement | ChoiceSetInput element on which text change was observed |
| queryText | String | Text in the Input.ChoiceSet entered by the user |
| completion |  | Completion block with choices[] as response or NSError in case of any failure

updateChoices method parameters in
| Parameter | Type | Description |
| :------- | :----- | :------------------------------------------------------------------------------------------
| choices[] | Choices [] | Dynamic choices for the query text from the service |

#### Debounce Logic

Debouncer is a helper which implements the debounce operation on a stream of data. e.g. When user is typing in a UITextField, each edit operation is pushed into the debouncer, but the debouncer will
only perform the callback when a certain minimum time has been elapsed since last keystroke by the user.


#### Loading experience

While the host resolves the request for dynamic choices requested by the sdk, we continue to show the static choices.

1. We can add a loader to indicate that dynamic choices are being fetched.
2. We fetch the dynamic choices silently and append the result once its available.

#### Failure scenarios 

1. We have to show error message to the user when bot return with the error
2. We will use a maximum time limit to fetch dynamic choices in the host config. We show an error message if the choices are not fetched in this time limit.
3. We will have a way to customize error message based on the host's response. Host can return localized error message to the SDK when invoke call completes. SDK will show error message on the UX.

### Option 2






### Option 3



### Option 4






<!-- END AUTO-GENERATED -->