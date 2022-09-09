// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT License.

#pragma once

#include "pch.h"
#include "ParseContext.h"

namespace AdaptiveCards
{
class ChoicesData
{
public:
    ChoicesData();
    ChoicesData(std::string type, std::string dataset, std::string value, int count, int skip) :
        m_type(type), m_dataset(dataset), m_value(value), m_count(count), m_skip(skip)
    {
    }

    bool ShouldSerialize() const;
    std::string Serialize() const;
    Json::Value SerializeToJsonValue() const;

    std::string GetType();
    const std::string GetType() const;
    void SetType(const std::string& type);

    std::string GetDataset();
    const std::string GetDataset() const;
    void SetDataset(const std::string& dataset);

    std::string GetValue();
    const std::string GetValue() const;
    void SetValue(const std::string& value);

    int GetCount();
    const int GetCount() const;
    void SetCount(const int& count);

    int GetSkip();
    const int GetSkip() const;
    void SetSkip(const int& skip);

    static std::shared_ptr<ChoicesData> Deserialize(ParseContext& context, const Json::Value& root);
    static std::shared_ptr<ChoicesData> DeserializeFromString(ParseContext& context, const std::string& jsonString);

private:
    std::string m_type;
    std::string m_dataset;
    std::string m_value;
    int m_count;
    int m_skip;
};

} // namespace AdaptiveCards
