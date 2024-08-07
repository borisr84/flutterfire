// Copyright 2024, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_data_connect_rest;

class RestTransport implements DataConnectTransport {
  RestTransport(this.transportOptions, this.options) {
    String protocol = 'http';
    if (transportOptions.isSecure == null ||
        transportOptions.isSecure == true) {
      protocol += 's';
    }
    String host = transportOptions.host;
    int port = transportOptions.port ?? 443;
    String project = options.projectId;
    String location = options.location;
    String service = options.serviceId;
    String connector = options.connector;
    _url =
        '$protocol://$host:$port/v1alpha/projects/$project/locations/$location/services/$service/connectors/$connector';
  }
  late String _url;
  @override
  TransportOptions transportOptions;
  @override
  DataConnectOptions options;
  Future<Data> invokeOperation<Data, Variables>(
      String queryName,
      Deserializer<Data> deserializer,
      Serializer<Variables>? serializer,
      Variables? vars,
      OperationType opType,
      String? token) async {
    String project = options.projectId;
    String location = options.location;
    String service = options.serviceId;
    String connector = options.connector;
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-goog-api-client': 'gl-dart/flutter fire/$packageVersion'
    };
    if (token != null) {
      headers['X-Firebase-Auth-Token'] = token;
    }
    Map<String, dynamic> body = {
      'name':
          'projects/$project/locations/$location/services/$service/connectors/$connector',
      'operationName': queryName,
    };
    if (vars != null && serializer != null) {
      body['variables'] = json.decode(serializer(vars));
    }
    String endpoint =
        opType == OperationType.query ? 'executeQuery' : 'executeMutation';
    try {
      http.Response r = await http.post(Uri.parse('$_url:$endpoint'),
          body: json.encode(body), headers: headers);
      return deserializer(jsonEncode(jsonDecode(r.body)['data']));
    } on Exception catch (e) {
      throw FirebaseDataConnectError(DataConnectErrorCode.other,
          'Failed to invoke operation: ${e.toString()}');
    }

    /// The response we get is in the data field of the response
    /// Once we get the data back, it's not quite json-encoded,
    /// so we have to encode it and then send it to the user's deserializer.
  }

  @override
  Future<Data> invokeQuery<Data, Variables>(
      String queryName,
      Deserializer<Data> deserializer,
      Serializer<Variables>? serializer,
      Variables? vars,
      String? token) async {
    return invokeOperation(
        queryName, deserializer, serializer, vars, OperationType.query, token);
  }

  @override
  Future<Data> invokeMutation<Data, Variables>(
      String queryName,
      Deserializer<Data> deserializer,
      Serializer<Variables>? serializer,
      Variables? vars,
      String? token) async {
    return invokeOperation(queryName, deserializer, serializer, vars,
        OperationType.mutation, token);
  }
}

DataConnectTransport getTransport(
        TransportOptions transportOptions, DataConnectOptions options) =>
    RestTransport(transportOptions, options);