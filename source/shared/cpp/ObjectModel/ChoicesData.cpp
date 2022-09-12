// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
#include "pch.h"
#include "ChoicesData.h"
#include "ParseContext.h"
#include "ParseUtil.h"

using namespace AdaptiveCards;

ChoicesData::ChoicesData()
{
}

std::string ChoicesData::Serialize() const
{
    return ParseUtil::JsonToString(SerializeToJsonValue());
}

Json::Value ChoicesData::SerializeToJsonValue() const
{
    Json::Value root;

    if (!m_type.empty())
    {
        root[AdaptiveCardSchemaKeyToString(AdaptiveCardSchemaKey::Type)] = GetType();
    }

    if (!m_dataset.empty())
    {
        root[AdaptiveCardSchemaKeyToString(AdaptiveCardSchemaKey::Dataset)] = GetDataset();
    }

    if (!m_value.empty())
    {
        root[AdaptiveCardSchemaKeyToString(AdaptiveCardSchemaKey::Value)] = GetValue();
    }

    if (m_count)
    {
        root[AdaptiveCardSchemaKeyToString(AdaptiveCardSchemaKey::Count)] = GetCount();
    }

    if (m_skip)
    {
        root[AdaptiveCardSchemaKeyToString(AdaptiveCardSchemaKey::Skip)] = GetSkip();
    }

    return root;
}

// Indicates non-default values have been set. If false, serialization can be safely skipped.
bool ChoicesData::ShouldSerialize() const
{
    return m_type.compare((AdaptiveCardSchemaKeyToString(AdaptiveCardSchemaKey::DataQuery))) != 0 && !m_dataset.empty();
}

std::shared_ptr<ChoicesData> ChoicesData::Deserialize(ParseContext& /*context*/, const Json::Value& json)
{
    auto choicesData = std::make_shared<ChoicesData>();

    auto type = ParseUtil::GetString(json, AdaptiveCardSchemaKey::Type, true);
    auto dataset = ParseUtil::GetString(json, AdaptiveCardSchemaKey::Dataset, true);
    if (type.compare((AdaptiveCardSchemaKeyToString(AdaptiveCardSchemaKey::DataQuery))) == 0 && !dataset.empty())
    {
        choicesData->SetType(type);
        choicesData->SetDataset(dataset);
        choicesData->SetValue(ParseUtil::GetString(json, AdaptiveCardSchemaKey::Value, false));
        choicesData->SetSkip(ParseUtil::GetInt(json, AdaptiveCardSchemaKey::Skip, false));
        choicesData->SetCount(ParseUtil::GetInt(json, AdaptiveCardSchemaKey::Count, false));
    }

    return choicesData;
}

std::shared_ptr<ChoicesData> ChoicesData::DeserializeFromString(ParseContext& context, const std::string& jsonString)
{
    return ChoicesData::Deserialize(context, ParseUtil::GetJsonValueFromString(jsonString));
}

const std::string ChoicesData::GetType() const
{
    return m_type;
}

std::string ChoicesData::GetType()
{
    return m_type;
}

void ChoicesData::SetType(const std::string& type)
{
    m_type = type;
}

const std::string ChoicesData::GetDataset() const
{
    return m_dataset;
}

std::string ChoicesData::GetDataset()
{
    return m_dataset;
}

void ChoicesData::SetDataset(const std::string& dataset)
{
    m_dataset = dataset;
}

const std::string ChoicesData::GetValue() const
{
    return m_value;
}

std::string ChoicesData::GetValue()
{
    return m_value;
}

void ChoicesData::SetValue(const std::string& value)
{
    m_value = value;
}

const int ChoicesData::GetSkip() const
{
    return m_skip;
}

int ChoicesData::GetSkip()
{
    return m_skip;
}

void ChoicesData::SetSkip(const int& skip)
{
    m_skip = skip;
}

const int ChoicesData::GetCount() const
{
    return m_count;
}

int ChoicesData::GetCount()
{
    return m_count;
}

void ChoicesData::SetCount(const int& count)
{
    m_count = count;
}
