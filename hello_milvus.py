from pymilvus import MilvusClient, DataType

# 1. 连接到 Milvus
# 默认情况下，Milvus 服务运行在 127.0.0.1:19530
try:
    client = MilvusClient(uri="http://localhost:19530")
    print("✅ 成功连接到 Milvus 服务")
except Exception as e:
    print(f"❌ 连接失败: {e}")
    exit()

# 定义 Collection 名称
COLLECTION_NAME = "hello_collection"
DIMENSION = 5  # 向量维度

# 2. 定义 Schema (表的结构)
schema = client.create_schema(
    collection_name=COLLECTION_NAME,
    auto_id=True,
    enable_dynamic_field=True, # 允许动态添加字段
)

# 定义向量字段和索引配置
schema.add_field(field_name="vector", datatype=DataType.FLOAT_VECTOR, dim=DIMENSION)
client.create_collection(schema)
print(f"✅ 成功创建 Collection: {COLLECTION_NAME}")

# 3. 插入数据 (Hello World)
data = [
    {
        "vector": [0.1, 0.2, 0.3, 0.4, 0.5],  # 我们的“Hello”向量
        "id_tag": 1,
        "text": "这是一个 Milvus Hello World 向量",
    }
]

res_insert = client.insert(COLLECTION_NAME, data)
print(f"✅ 成功插入 {len(res_insert['ids'])} 条数据")

# 4. 搜索数据 (验证)
search_vector = [0.1, 0.2, 0.3, 0.4, 0.5] # 用插入的向量本身进行搜索

res_search = client.search(
    collection_name=COLLECTION_NAME,
    data=[search_vector],
    limit=1,
    output_fields=["text"],
)

# 5. 输出结果
print("\n--- 搜索结果 ---")
# 搜索结果是一个列表的列表，我们只需要第一个结果
hit = res_search[0][0]
print(f"⭐ 匹配到的文本: {hit['entity']['text']}")
print(f"⭐ 距离 (Distance): {hit['distance']}")

# 6. 清理
client.drop_collection(COLLECTION_NAME)
print(f"\n✅ 清理完成，删除 Collection: {COLLECTION_NAME}")