using Artemis.API.Entities;

namespace Artemis.API.Utilities;

public static class RoomLifecycleHelper
{
    public static bool IsExpired(Room room)
    {
        var end = LifecycleEndUtc(room.CreateDate, room.LifeCycle);
        return DateTime.UtcNow > end;
    }

    public static DateTime LifecycleEndUtc(DateTime createDate, double lifeCycleMinutes)
    {
        var created = NormalizeToUtc(createDate);
        return created.AddMinutes(lifeCycleMinutes);
    }

    private static DateTime NormalizeToUtc(DateTime dt)
    {
        return dt.Kind switch
        {
            DateTimeKind.Utc => dt,
            DateTimeKind.Local => dt.ToUniversalTime(),
            _ => DateTime.SpecifyKind(dt, DateTimeKind.Utc),
        };
    }
}
