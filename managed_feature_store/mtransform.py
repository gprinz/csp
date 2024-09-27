from pyspark.sql import functions as F
from pyspark.sql.window import Window
from pyspark.ml import Transformer
from pyspark.sql.dataframe import DataFrame

# Define the Transformer for feature creation
class TaxiFeatureTransformer(Transformer):
    def _transform(self, df: DataFrame) -> DataFrame:
        # Time windows in seconds
        def days(i):
            return i * 86400

        def hours(i):
            return i * 3600

        # Define window ranges (partition by vendorID, ensure time series integrity by looking backward only)
        w_1h = Window.partitionBy("vendorID").orderBy(F.col("tpepPickupDateTime").cast("long")).rangeBetween(-hours(1), 0)
        w_3d = Window.partitionBy("vendorID").orderBy(F.col("tpepPickupDateTime").cast("long")).rangeBetween(-days(3), 0)
        w_7d = Window.partitionBy("vendorID").orderBy(F.col("tpepPickupDateTime").cast("long")).rangeBetween(-days(7), 0)

        # Calculate trip duration in minutes and add rolling window features
        df = df.withColumn(
            "trip_duration",
            (F.unix_timestamp("tpepDropoffDateTime") - F.unix_timestamp("tpepPickupDateTime")) / 60
        ).withColumn("total_amount_7d_sum", F.sum("totalAmount").over(w_7d)
        ).withColumn("total_amount_7d_avg", F.avg("totalAmount").over(w_7d)
        ).withColumn("trip_3d_count", F.count("doLocationId").over(w_3d)
        ).withColumn("total_amount_3d_sum", F.sum("totalAmount").over(w_3d)
        ).withColumn("total_amount_3d_avg", F.avg("totalAmount").over(w_3d)
        ).withColumn("tip_amount_7d_avg", F.avg("tipAmount").over(w_7d)
        ).withColumn("trips_last_hour_count", F.count("doLocationId").over(w_1h)
        )

        # Add additional features
        df = df.withColumn("hour_of_day", F.hour("tpepPickupDateTime")
        ).withColumn("distance_duration_ratio", F.col("tripDistance") / F.col("trip_duration")
        ).withColumn("has_surcharge", F.when(F.col("extra") > 0, 1).otherwise(0))

        # Select relevant columns
        return df.select(
            "vendorID",
            "trip_duration",
            "trip_3d_count",
            "total_amount_3d_sum",
            "total_amount_3d_avg",
            "total_amount_7d_sum",
            "total_amount_7d_avg",
            "tip_amount_7d_avg",
            "trips_last_hour_count",
            "passengerCount",
            "tripDistance",
            "hour_of_day",
            "distance_duration_ratio",
            "has_surcharge",
            "tpepPickupDateTime",
            "doLocationId"
        )
